# Redmine Serverless

Redmine Serverless(`redmine_serverless`)は、Redmine を AWS Lambda で動かすための Redmine のプラグインです。[Serverless](https://redmine-kit.github.io/serverless/ja/architecture.html) が、Lambda 用のイメージに入れて使います。Redmine 本体のファイルは書き換えず、Redmine の標準の拡張の仕組みだけで作ります。今は設計段階で、資料だけがあります。

- [準備](setup.md): 前提、インストール、設定、AWS のリソース、ネットワーク、テスト
- [IAM の権限](iam.md): 権限、例のポリシー、リソースベースのポリシー
- [管理画面](admin.md): 状態と接続、Lambda で使えない Redmine の設定

<a id="features"></a>

## 機能

Redmine の標準の動きをできるだけ保ち、自前で書くのは、Lambda で動かすのに要る部分だけにします。機能ごとに、有効にする条件を持たせます。条件がそろわない機能は、Redmine の標準のままに動きます。

| 機能 | 中身 | 有効にする条件 | 資料 |
| --- | --- | --- | --- |
| Lambda での実行 | Lambda Web Adapter の `/events` に 204 を返す Rack のミドルウェア、アセットの自動の書き出しを止める設定、Lambda で使えない Redmine の設定を無効に固定して画面に表示する | `REDMINE_ROLE` がある | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |
| 管理画面 | 共有の「Serverless」のメニューの「状態と接続」のタブと、ほかのプラグインの確認 | 管理者 | [admin.md](admin.md) |

AWS のためのほかの機能は、別のプラグインです。Lambda 以外でも動きます。

| プラグイン | 中身 |
| --- | --- |
| [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/ja/) | S3 の添付ファイル。署名付き URL で CloudFront を通すアップロードとダウンロード、`/tmp` のキャッシュ |
| [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/ja/) | SES でのメール。エラーの種類ごとの送信のやり直し、受信と取り込み、プロジェクトごとのアドレス |
| [Redmine Serverless SQS](https://redmine-kit.github.io/redmine_serverless_sqs/ja/) | SQS でのジョブ。`aws-activejob-sqs` の設定、ジョブの失敗の記録、送り直し |
| [Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/ja/) | SSM Parameter Store の設定と秘密の値。Rails が起動する前に読む |

どのプラグインも、どれをインストールしていても、管理の画面を Redmine の管理のメニューの 1 つの項目「Serverless」の下に、1 つのページのタブとして置きます([admin.md](admin.md#the-serverless-menu))。このプラグインをインストールしているときは、それぞれの確認が、接続の確認にも加わります。

- **コードの分け方:** プラグインの中で、機能ごとにディレクトリ(`lib/redmine_serverless/` の下)を分け、機能どうしは、決めた入口だけでつなぎます。
- **gem:** プラグインは自分では AWS の API を呼ばないので、AWS の SDK の gem は要りません。
- **テスト:** Redmine の標準の仕組み(`rake redmine:plugins:test`)で、差し替えた処理ごとにテストを書きます([setup.md](setup.md#tests))。
- **migration:** ありません。
