# 準備

Redmine Serverless を使う Redmine に要るもの(インストール、設定、前提にする AWS のリソース、IAM の権限、ネットワーク)です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これを CloudFormation でまとめて作ります。このページは、手で用意するときや、Serverless が作るものを確認するときのためのものです。プラグインは設計段階なので、下の内容は設計で、コードを書くときに確認します。

<a id="requirements"></a>

## 前提

- PostgreSQL の上の Redmine 7.0 以降。
- AWS Lambda では、[Serverless](https://redmine-kit.github.io/serverless/ja/lambda.html#image) と同じように、Lambda Web Adapter を入れたコンテナイメージ。Lambda の外(`REDMINE_ROLE` がない)では、プラグインの機能は動かず、Redmine の標準のままです。
- ジョブは、AWS の公式の gem `aws-activejob-sqs` で SQS に入れる(ジョブの失敗の記録と「ジョブ」の画面は、これを前提にします)。

<a id="installation"></a>

## インストール

1. プラグインを `plugins/redmine_serverless` に置き、`bundle install` を実行します(プラグインの `Gemfile` は Redmine の `Gemfile` が読み込みます)。
2. `bin/rake redmine:plugins:migrate` を実行します。失敗したジョブの記録の表(`serverless_job_failures`)ができます。

<a id="configuration"></a>

## 設定

| 設定 | 置き場所 | 中身 |
| --- | --- | --- |
| `REDMINE_ROLE` | 関数ごとの環境変数 | `web`、`worker`、`task`。Lambda のための機能を有効にする([README.md](README.md#features)) |
| `REDMINE_JOBS_QUEUE_URL` | 環境変数 | ジョブのキューの URL。SQS のアダプターと「ジョブ」の画面が使う |
| ジョブのキューのアダプター | `config/additional_environment.rb` | `REDMINE_ROLE` があるときに `config.active_job.queue_adapter = :sqs`、キューは `config/aws_active_job_sqs.yml`([Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html#background-jobs)) |

- **デッドレターキュー:** 「ジョブ」の画面のために、プラグインがジョブのキューのデッドレターキューをどう見つけるかは、コードを書くときに決めます(未定)。
- **SSM の設定:** 起動のときに SSM Parameter Store から設定と秘密の値を読むには、[Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/ja/) を使います。「状態と接続」の画面の接続の確認も、SSM を呼びます。

<a id="aws-resources"></a>

## AWS のリソース

| リソース | 設定 |
| --- | --- |
| SQS のジョブのキュー | 標準のキュー。可視性のタイムアウトは、ジョブを動かす関数のタイムアウトより長く。3 回受け取ったらデッドレターキューに移す設定(redrive policy) |
| SQS のデッドレターキュー | 3 回失敗したジョブを受ける。「ジョブ」の画面が `StartMessageMoveTask` で戻す |
| ジョブを動かす関数 | `REDMINE_ROLE=worker`。ジョブのキューに SQS のイベントソースマッピング(バッチの大きさは 1)([Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html#background-jobs)) |

<a id="iam-permissions"></a>

## IAM の権限

プラグイン自身が AWS を呼ぶための権限です。Lambda の権限(ログ、VPC の中で動くこと)と、ほかのプラグインの権限は含めません。ロールの全体は [Serverless の iam.md](https://redmine-kit.github.io/serverless/ja/iam.html) にあります。

| 権限 | リソース | ロール | 使いみち |
| --- | --- | --- | --- |
| `sqs:GetQueueAttributes` | ジョブのキューと、そのデッドレターキュー | 画面の要求 | 「ジョブ」の画面のキューの件数と、「状態と接続」の SQS の確認 |
| `sqs:SendMessage` | ジョブのキュー | 画面の要求 | 「ジョブ」の画面からの、記録したジョブの送り直し(ジョブを入れること全般にも要る) |
| `sqs:StartMessageMoveTask`、`sqs:ListMessageMoveTasks` | デッドレターキュー | 画面の要求 | デッドレターキューをジョブのキューに戻す |
| `ssm:GetParametersByPath` | `arn:aws:ssm:<region>:<account>:parameter/<instance>/env` とその下 | 画面の要求 | 「状態と接続」の SSM の確認(1 件) |

画面の要求のロールの、ポリシーの例です。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "JobsPage",
      "Effect": "Allow",
      "Action": ["sqs:GetQueueAttributes", "sqs:SendMessage"],
      "Resource": [
        "arn:aws:sqs:<region>:<account>:<instance>-jobs",
        "arn:aws:sqs:<region>:<account>:<instance>-jobs-dlq"
      ]
    },
    {
      "Sid": "Redrive",
      "Effect": "Allow",
      "Action": ["sqs:StartMessageMoveTask", "sqs:ListMessageMoveTasks"],
      "Resource": "arn:aws:sqs:<region>:<account>:<instance>-jobs-dlq"
    },
    {
      "Sid": "ConnectionCheck",
      "Effect": "Allow",
      "Action": "ssm:GetParametersByPath",
      "Resource": [
        "arn:aws:ssm:<region>:<account>:parameter/<instance>/env",
        "arn:aws:ssm:<region>:<account>:parameter/<instance>/env/*"
      ]
    }
  ]
}
```

- **メッセージを戻す権限:** `StartMessageMoveTask` を呼ぶ側に、デッドレターキューへの `sqs:ReceiveMessage` と `sqs:DeleteMessage`、ジョブのキューへの `sqs:SendMessage` も要るかは、作るときに確認します(未確認)。

<a id="network"></a>

## ネットワーク

| 呼ぶ先 | API | インターネットに出られない VPC の中では |
| --- | --- | --- |
| SQS | `GetQueueAttributes`、`SendMessage`、`StartMessageMoveTask` | インターフェースのエンドポイント `com.amazonaws.<region>.sqs` |
| SSM | `GetParametersByPath`(接続の確認) | インターフェースのエンドポイント `com.amazonaws.<region>.ssm` |
| データベース | PostgreSQL(接続の確認) | 関数からデータベースのポートへの、セキュリティグループの許可 |

<a id="tests"></a>

## テスト

Redmine の標準のプラグインのテスト(`bin/rake redmine:plugins:test NAME=redmine_serverless`)です。Serverless のスクリプトが実行し、`REDMINE_SERVERLESS_DIR` でこのプラグインの手元のチェックアウトを使えます([Serverless の testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#running-on-lambda-redmine_serverless))。
