# Redmine Serverless

Redmine Serverless(`redmine_serverless`)は、Redmine を AWS Lambda で動かすための Redmine のプラグインです。[Serverless](https://redmine-kit.github.io/serverless/ja/architecture.html) が、Lambda 用のイメージに入れて使います。Redmine 本体のファイルは書き換えず、Redmine の標準の拡張の仕組みだけで作ります。今は開発の初期です。

- [導入](setup.md): 動作環境、インストール、設定、AWS リソース、ネットワーク、テスト
- [IAM 権限](iam.md): 権限、ポリシーの例、リソースベースのポリシー
- [管理画面](admin.md): ステータス、Lambda で使えない Redmine の設定
- [Lambda で動かすとき](#running-on-lambda): `/events`、転送されたホスト、アセットの確認、テスト

<a id="features"></a>

## 機能

Redmine の標準の動きをできるだけ保ち、自前で書くのは、Lambda で動かすのに要る部分だけにします。機能ごとに、有効にする条件を持たせます。条件がそろわない機能は、Redmine の標準のままに動きます。

| 機能 | 内容 | 有効にする条件 | 資料 |
| --- | --- | --- | --- |
| Lambda での実行 | Lambda Web Adapter の `/events` に 204 を返す Rack のミドルウェア、CloudFront の `X-Forwarded-Host` を `Host` にする Rack のミドルウェア、アセットの自動の書き出しを止める設定、Lambda で使えない Redmine の設定を無効に固定して画面に表示する | `REDMINE_ROLE` がある | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |
| 管理画面 | 共有の「Serverless」のメニューの「ステータス」のタブと、ほかのプラグインの確認 | 管理者 | [admin.md](admin.md) |

AWS のためのほかの機能は、別のプラグインです。Lambda 以外でも動きます。

| プラグイン | 内容 |
| --- | --- |
| [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/ja/) | S3 の添付ファイル。署名付き URL で CloudFront を通すアップロードとダウンロード、`/tmp` のキャッシュ |
| [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/ja/) | SES でのメール。エラーの種類ごとの送信のやり直し、受信と取り込み、プロジェクトごとのアドレス |
| [Redmine Serverless SQS](https://redmine-kit.github.io/redmine_serverless_sqs/ja/) | SQS でのジョブ。`aws-activejob-sqs` の設定、ジョブの失敗の記録、送り直し |
| [Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/ja/) | SSM Parameter Store の設定と秘密の値。Rails が起動する前に読む |

どのプラグインも、どれをインストールしていても、管理の画面を Redmine の管理のメニューの 1 つの項目「Serverless」の下に、1 つのページのタブとして置きます([admin.md](admin.md#the-serverless-menu))。このプラグインをインストールしているときは、それぞれの確認が、接続テストにも加わります。

<a id="code-layout"></a>

## コード構成

Rails の初期化より前に要るもの(`/events` と転送されたホストのミドルウェア、アセットの設定)は、`boot/redmine_serverless.rb` にあります。プラグインは gem でもあるので、Bundler がこのファイルを読み込みます([setup.md](setup.md#installation))。ほかは Redmine が読み込む `lib/redmine_serverless/` と `app/` にあり、`init.rb` が有効にします。

プラグインは自分では AWS の API を呼ばないので、AWS SDK の gem は要りません。データベースのテーブルも追加しないので、実行する migration はありません。差し替えた処理ごとに、Redmine の標準の仕組み(`rake redmine:plugins:test`)でテストを書いています([setup.md](setup.md#tests))。

<a id="running-on-lambda"></a>

## Lambda で動かすとき

Lambda の上(`REDMINE_ROLE` があるとき)では、プラグインが Redmine を次のように合わせます。イメージと関数は、[Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html) にあります。

| 何を | どうする | 理由 |
| --- | --- | --- |
| `/events` | ミドルウェアの並びの先頭の Rack のミドルウェア(`boot/` が登録する)が、データベースやセッションに触れる前に、`/events` に 204 を返す。ほかのパスはそのまま通す | Lambda Web Adapter は、関数 URL を通らないイベント(ウォームアップなど)を、`/events` への POST として Puma に渡す(`AWS_LWA_PASS_THROUGH_PATH`)。ロールがなければ、`/events` はふつうのパス(404) |
| 転送されたホスト | `/events` のすぐ後の Rack のミドルウェア(`boot/` が登録する)が、Rails のホストの認可より前に、`X-Forwarded-Host` の最後の値を `Host` に入れる。`X-Forwarded-Host` がなければ `Host` はそのまま | リクエストは CloudFront と関数 URL を通り、`Host` は関数 URL 自身のホスト名になる。関数 URL とオリジンアクセスコントロールにはそれが要る。CloudFront は Redmine のドメインを `X-Forwarded-Host` で渡す。これはオリジンのカスタムヘッダーで、ビューワーが送った同じ名前のヘッダーを置き換える。Rails のホストの認可は、`Host` と `X-Forwarded-Host` のどちらかが `config.hosts` になければリクエストをブロックし、Lambda の `config.hosts` はドメインだけ([Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html#host-and-scheme))。そのため関数 URL のホスト名は受け付けない。`X-Forwarded-Host` がないか、ほかのホストが入ったリクエストは 403 でブロックされる |
| アセットの確認 | `config.assets.redmine_detect_update` を `false` にする。`boot/` が `after_initialize` で設定し、Redmine 自身の確認より前に動く | `production.rb` は `true` にし、Redmine は起動のときに古いアセットを `public/assets` に書き出す。Lambda ではファイルシステムが読み取り専用で、イメージにはビルドしたアセットがある |
| 使えない Redmine の設定 | 無効に固定し、設定の画面に表示する | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |

<a id="tests"></a>

### テスト

| 対象 | 確認すること |
| --- | --- |
| `/events` | SQL もセッションの Cookie もなしに 204 を返す。ほかのパスは通す。ロールがなければ 404。ミドルウェアは先頭にある |
| 転送されたホスト | ドメインだけを許す Rails のホストの認可の前に置き、`Host` に関数 URL のホスト名を入れたリクエストを送る。`X-Forwarded-Host` にドメインがあれば 200 で、URL もドメインで作る。値が複数なら最後の値を使う。`X-Forwarded-Host` がない、ほかのホスト、関数 URL のホスト名なら 403。ロールがなければ 403(Rails の標準の動作)。ミドルウェアは `/events` のすぐ後にある |
| アセットの確認 | `REDMINE_ROLE` のある新しいプロセスで `false`。ロールがなければ変わらない |
| 固定する設定 | Lambda では読み出しが固定の値を返し、保存しても変わらない。ロールがなければ Redmine の標準のまま。設定の画面は入力を無効にして表示する |
| 差し替えたコード | Redmine の `Setting.define_setting` の SHA-256 を比べ、Redmine のバージョンアップで変わったら気づけるようにする |
| 管理画面 | 管理者だけ。秘密を画面に出さない。データベースの確認と、その失敗。メニューの項目は 1 つ |

<a id="sponsors"></a>

## スポンサー

<Sponsors><a href="https://www.keyselect.co.jp/">KEY SELECT</a> <a href="https://localstack.cloud">LocalStack</a></Sponsors>

<a id="license"></a>

## ライセンス

Redmine Serverless は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](../../LICENSE) を参照してください。Redmine の非公式のプラグインです。
