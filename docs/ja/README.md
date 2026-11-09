# Redmine Serverless

Redmine Serverless(`redmine_serverless`)は、Redmine を AWS Lambda で動かすための Redmine のプラグインです。[Serverless](https://redmine-kit.github.io/serverless/ja/architecture.html) が、Lambda 用のイメージに入れて使います。Redmine 本体のファイルは書き換えず、Redmine の標準の拡張の仕組みだけで作ります。今は設計段階で、資料だけがあります。

- [準備](setup.md): インストール、設定、AWS のリソース、IAM の権限、ネットワーク
- [管理画面](admin.md): 状態と接続、Lambda で使えない設定、ジョブ

<a id="features"></a>

## 機能

Redmine の標準の動きをできるだけ保ち、自前で書くのは、Lambda で動かすのに要る部分だけにします。機能ごとに、有効にする条件を持たせます。条件がそろわない機能は、Redmine の標準のままに動きます。

| 機能 | 中身 | 種類 | 有効にする条件 | 資料 |
| --- | --- | --- | --- | --- |
| Lambda での実行 | Lambda Web Adapter の `/events` に 204 を返す Rack のミドルウェア、アセットの自動の書き出しを止める設定、Lambda で使えない Redmine の設定を無効に固定して画面に表示する([admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda)) | Lambda に要る | `REDMINE_ROLE` がある | [lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html) |
| ジョブの失敗の記録 | 最後に失敗したジョブ(やり直しを使い切ったもの、やり直さないエラーのもの)を中身と一緒に記録し、送り直せるようにする | Lambda に要る(ジョブは SQS を通って別の関数が動かすので、失敗が画面から見えない) | `REDMINE_ROLE=worker` | [admin.md](admin.md#jobs) |
| 管理画面 | 状態と接続、ジョブ | Lambda の Redmine の運用に要る(AWS の状態を Redmine から見る) | 管理者 | [admin.md](admin.md) |

AWS のためのほかの機能は、別のプラグインです。Lambda の外でも動きます。

| プラグイン | 中身 |
| --- | --- |
| [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/ja/) | S3 の添付ファイル。直接のアップロード、ダウンロードとサムネイルの署名付き URL、`/tmp` のキャッシュ |
| [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/ja/) | SES でのメール。エラーの種類ごとの送信のやり直し、受信と取り込み、プロジェクトごとのアドレス |

これらのプラグインを入れると、その管理画面が、このプラグインの「サーバーレス」の画面のタブに加わり、その確認が接続の確認に加わります。

- **コードの分け方:** プラグインの中で、機能ごとにディレクトリ(`lib/redmine_serverless/` の下)を分け、機能どうしは、決めた入口だけでつなぎます。
- **gem:** プラグインが使う gem(`aws-sdk-sqs` など)は、プラグインの `Gemfile` に書きます。Redmine の `Gemfile` は、`plugins/*/Gemfile` も読み込みます。
- **テスト:** Redmine の標準の仕組み(`rake redmine:plugins:test`)で、差し替えた処理ごとにテストを書きます([testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#plugin-tests))。
- **migration:** 失敗したジョブの記録(`serverless_job_failures`)のテーブルを足します([admin.md](admin.md#jobs))。デプロイでは、`redmine:plugins:migrate` も実行します。
