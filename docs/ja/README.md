# Redmine Serverless

Redmine Serverless(`redmine_serverless`)は、Redmine を AWS Lambda で動かすための Redmine のプラグインです。[Serverless](https://redmine-kit.github.io/serverless/ja/architecture.html) が、Lambda 用のイメージに入れて使います。Redmine 本体のファイルは書き換えず、Redmine の標準の拡張の仕組みだけで作ります。今は開発の初期です(バージョン 0.1.0)。

- [準備](setup.md): 前提、インストール、設定、AWS のリソース、ネットワーク、テスト
- [IAM の権限](iam.md): 権限、例のポリシー、リソースベースのポリシー
- [管理画面](admin.md): 状態と接続、Lambda で使えない Redmine の設定
- [Lambda で動かすとき](#running-on-lambda): `/events`、アセットの確認、テスト

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

- **コードの分け方:** Rails の初期化より前に要るもの(`/events` のミドルウェアとアセットの設定)は `boot/redmine_serverless.rb` にあり、Bundler が読み込みます。プラグインは gem でもあるからです([setup.md](setup.md#installation))。ほかは Redmine が読み込む `lib/redmine_serverless/` と `app/` にあり、`init.rb` が有効にします。
- **gem:** プラグインは自分では AWS の API を呼ばないので、AWS の SDK の gem は要りません。
- **テスト:** Redmine の標準の仕組み(`rake redmine:plugins:test`)で、差し替えた処理ごとにテストを書きます([setup.md](setup.md#tests))。
- **migration:** ありません。

<a id="running-on-lambda"></a>

## Lambda で動かすとき

Lambda の上(`REDMINE_ROLE` があるとき)では、プラグインが Redmine を次のように合わせます。イメージと関数は、[Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html) にあります。

| 何を | どうする | 理由 |
| --- | --- | --- |
| `/events` | ミドルウェアの並びの先頭の Rack のミドルウェア(`boot/` が登録する)が、データベースやセッションに触れる前に、`/events` に 204 を返す。ほかのパスはそのまま通す | Lambda Web Adapter は、関数 URL を通らないイベント(温めなど)を、`/events` への POST として Puma に渡す(`AWS_LWA_PASS_THROUGH_PATH`)。ロールがなければ、`/events` はふつうのパス(404) |
| アセットの確認 | `config.assets.redmine_detect_update` を `false` にする。`boot/` が `after_initialize` で設定し、Redmine 自身の確認より前に動く | `production.rb` は `true` にし、Redmine は起動のときに古いアセットを `public/assets` に書き出す。Lambda ではファイルシステムが読み取り専用で、イメージにはビルドしたアセットがある |
| 使えない Redmine の設定 | 無効に固定し、設定の画面に表示する | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |

<a id="tests"></a>

### テスト

| 対象 | 確認すること |
| --- | --- |
| `/events` | SQL もセッションの Cookie もなしに 204 を返す。ほかのパスは通す。ロールがなければ 404。ミドルウェアは先頭にある |
| アセットの確認 | `REDMINE_ROLE` のある新しいプロセスで `false`。ロールがなければ変わらない |
| 固定する設定 | Lambda では読み出しが固定の値を返し、保存しても変わらない。ロールがなければ Redmine の標準のまま。設定の画面は入力を無効にして表示する |
| 差し替えたコード | Redmine の `Setting.define_setting` の SHA-256 を比べ、Redmine のバージョンアップで変わったら気づけるようにする |
| 管理画面 | 管理者だけ。秘密を画面に出さない。データベースの確認と、その失敗。メニューの項目は 1 つ |

<a id="sponsors"></a>

## スポンサー

<Sponsors><a href="https://localstack.cloud">LocalStack</a></Sponsors>

<a id="license"></a>

## ライセンス

Redmine Serverless は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](../../LICENSE) を参照してください。Redmine projectとは関係ありません。
