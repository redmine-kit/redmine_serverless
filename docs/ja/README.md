# Redmine Serverless

Redmine Serverless(`redmine_serverless`)は、Redmine を AWS のサーバーレス(Lambda と AWS のマネージドサービス)で動かすための Redmine のプラグインです。[redmine-serverless](https://redmine-kit.github.io/redmine-serverless/ja/architecture.html) が、Lambda 用のイメージに入れて使います。Redmine 本体のファイルは書き換えず、Redmine の標準の拡張の仕組みだけで作ります。今は設計の段階で、資料だけがあります。

- [S3 の添付ファイル](attachments.md): 保存、アップロード、ダウンロード、キャッシュ
- [管理画面](admin.md): 状態と接続、メールの送信、ジョブ、メールの受信、添付ファイルの S3

<a id="features"></a>

## 中の機能

Redmine の標準の動きをできるだけ保ち、自前で書くのは、サーバーレスで動かすのに要る部分だけにします。機能ごとに、有効にする条件を持たせます。条件がそろわない機能は、Redmine の標準のままに動きます。S3 の添付ファイルだけを、Lambda でない環境で使うこともできます。

| 機能 | 中身 | 種類 | 有効にする条件 | 資料 |
| --- | --- | --- | --- | --- |
| S3 の添付ファイル | 保存と削除、S3 へのアップロード(署名付きの POST)、署名付き URL へのリダイレクト(ダウンロードとサムネイル)、`/tmp` のキャッシュ、CSV のインポートのファイル、一括のダウンロードの zip | サーバーレスに要る(書き込めるディスクがない、6 MB の制限) | S3 のバケットの設定(環境変数)がある | [attachments.md](attachments.md) |
| Lambda での実行 | Lambda Web Adapter の `/events` に 204 を返す Rack のミドルウェア、アセットの自動の書き出しを止める設定、Lambda で使えない Redmine の設定を無効に固定して画面に表示する([admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda)) | サーバーレスに要る | `REDMINE_ROLE` がある | [lambda.md](https://redmine-kit.github.io/redmine-serverless/ja/lambda.html) |
| メールの送信のやり直し | `redmine-worker` での `raise_delivery_errors`、エラーの種類ごとのやり直し、失敗の記録 | サーバーレスに要る(ジョブを SQS で別の関数が送るので、失敗が画面から見えない) | `REDMINE_ROLE=worker` | [mail.md](https://redmine-kit.github.io/redmine-serverless/ja/mail.html#when-sending-fails) |
| メールの受信 | SES で受けたメールの取り込み(rake のタスク `redmine_serverless:receive_mail`。中では Redmine の標準の `MailHandler` を使う)、なりすましと迷惑メールの確認、取り込みの記録 | サーバーレスに要る(IMAP の受信箱がなく、SES で受ける) | 受信の設定がある | [mail.md](https://redmine-kit.github.io/redmine-serverless/ja/mail.html#importing) |
| プロジェクトごとのアドレス | プロジェクトごとの受信のアドレスと送信元、全体用のアドレス、プロジェクトの設定の「メール」のタブ | Redmine の標準にない機能。Redmine の標準では、送信元は 1 つで、プロジェクトはサブアドレス(`redmine+識別子@…`)で選ぶ | プラグインの設定で有効にする。無効なら Redmine の標準と同じ | [mail.md](https://redmine-kit.github.io/redmine-serverless/ja/mail.html#addresses-per-project) |
| 管理画面 | 状態と接続、メールの送信(SES の状態)、ジョブ、メールの受信、添付ファイルの S3 | サーバーレスの運用に要る(AWS の状態を Redmine から見る)。Redmine の標準にある画面(テストのメールなど)は足さない | 管理者。使っていない機能のタブは出さない | [admin.md](admin.md) |

- **コードの分け方:** プラグインの中で、機能ごとにディレクトリ(`lib/redmine_serverless/` の下)を分け、機能どうしは、決めた入口だけでつなぎます。
- **gem:** プラグインが使う gem(`aws-sdk-s3` など)は、プラグインの `Gemfile` に書きます。Redmine の `Gemfile` は、`plugins/*/Gemfile` も読み込みます。
- **テスト:** Redmine の標準の仕組み(`rake redmine:plugins:test`)で、差し替えた処理ごとにテストを書きます([testing.md](https://redmine-kit.github.io/redmine-serverless/ja/testing.html#plugin-tests))。
- **migration:** 失敗したジョブの記録(`serverless_job_failures`)、受け取ったメールの記録(`serverless_received_mails`)、プロジェクトのメールの設定(`serverless_project_mail_settings`)のテーブルを足します([admin.md](admin.md))。デプロイでは、`redmine:plugins:migrate` も実行します。

