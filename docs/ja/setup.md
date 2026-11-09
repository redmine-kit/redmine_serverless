# 準備

Redmine Serverless を使う Redmine に要るもの(インストール、設定、前提にする AWS のリソース、IAM の権限、ネットワーク)です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作ります。このページは、手で用意するときや、Serverless が作るものを確認するときのためのものです。プラグインは設計段階なので、下の内容は設計で、コードを書くときに確認します。

<a id="requirements"></a>

## 前提

- PostgreSQL の上の Redmine 7.0 以降。
- AWS Lambda では、[Serverless](https://redmine-kit.github.io/serverless/ja/lambda.html#image) と同じく、Lambda Web Adapter を入れたコンテナイメージ。Lambda 以外(`REDMINE_ROLE` がないとき)では、プラグインの機能は動かず、Redmine は標準のままに動きます。

<a id="installation"></a>

## インストール

**プラグインの取り方:** Docker なら、ghcr.io のプラグインのイメージから、digest で固定して写します(タグは、`main` への push のたびに `main` と `sha-<コミット>`、リリースは `v*`)。

```dockerfile
COPY --from=ghcr.io/redmine-kit/redmine_serverless:main@sha256:<digest> /redmine_serverless plugins/redmine_serverless/
```

Docker を使わないなら、リポジトリを clone するか(`git clone https://github.com/redmine-kit/redmine_serverless.git plugins/redmine_serverless`)、リリースを公開したあとは、そのアーカイブを `plugins/redmine_serverless` に展開します。

1. プラグインを `plugins/redmine_serverless` に置き、`bundle install` を実行します(プラグインの `Gemfile` は、Redmine の `Gemfile` が読み込みます)。
2. migration は要りません。

<a id="configuration"></a>

## 設定

| 設定 | 場所 | 中身 |
| --- | --- | --- |
| `REDMINE_ROLE` | 関数ごとの環境変数 | `web`、`worker`、`task`。Lambda のための機能を有効にする([README.md](README.md#features)) |

- **SSM の設定:** 起動のときに SSM Parameter Store から設定と秘密の値を読むには、[Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/ja/) を使います。それを入れると、「状態と接続」に、読んだパラメーターの名前が出ます。

<a id="aws-resources"></a>

## AWS のリソース

| リソース | 設定 |
| --- | --- |
| Lambda の関数 | `REDMINE_ROLE` を設定し、Lambda Web Adapter で Redmine を動かす、コンテナイメージの関数([Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html)) |

<a id="iam-permissions"></a>

## IAM の権限

プラグインに要る権限と例のポリシーは、[iam.md](iam.md) にあります。

<a id="network"></a>

## ネットワーク

| 行き先 | API | インターネットに出られない VPC の中では |
| --- | --- | --- |
| データベース | PostgreSQL(「状態と接続」のデータベースの確認) | 関数からデータベースのポートへの、セキュリティグループの規則 |

<a id="tests"></a>

## テスト

Redmine の標準のプラグインのテストです(`bin/rake redmine:plugins:test NAME=redmine_serverless`)。Serverless が、自分のスクリプトで実行します。スクリプトは、`REDMINE_SERVERLESS_DIR` で、手元のこのプラグインのチェックアウトを使えます([Serverless の testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#running-on-lambda-redmine_serverless))。

<a id="to-verify"></a>

## 確認すること

- テンプレートを差し替えずに、フック `view_layouts_base_html_head` だけで、Redmine の設定の画面を変えられるか([admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda))
