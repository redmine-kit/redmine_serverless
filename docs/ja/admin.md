# 管理画面

Redmine Serverless が Redmine の管理のメニューに足す画面の設計です。画面の名前の「使う機能」は、プラグインの中の機能([プラグインの機能](README.md#features))です。使っていない機能の画面は出しません。メールの送信と受信、ジョブ、添付ファイルの S3、AWS への接続の状態を、Redmine の画面で確認し、操作できるようにします。

この資料の仕様は、2026-11-08 時点の公式の情報と、Redmine 7.0.3 のソースで確認したものです。出典は [sources.md](https://redmine-kit.github.io/serverless/ja/sources.html) にあります。

<a id="approach"></a>

## 方針

- **管理者だけ:** どの画面も、Redmine の管理者だけが開けます。Redmine の管理の画面と同じ確認(`require_admin`)を使います。
- **秘密の値は出さない:** SSM Parameter Store の値、`SECRET_KEY_BASE`、データベースの認証のトークンは、画面に出しません。パラメーターの名前と、読めたかどうかだけを出します。
- **AWS の API は必要なときだけ呼ぶ:** 画面を開いただけで多くの API を呼ばないよう、状態は 1 分だけキャッシュし、重い確認はボタンを押したときにジョブで行います。
- **秘密でない設定は画面で変える:** メールの受信のオプションなど、秘密でない設定は、プラグインの設定(Redmine の `Setting.plugin_*`、データベースに入る)にし、画面で変えられるようにします。AWS のリソースの名前など、インフラで決まる値は、環境変数のまま表示だけします。
- **操作は記録する:** 送り直しや削除などの操作は、Redmine のログに、誰がいつ何をしたかを残します。

<a id="list-of-pages"></a>

## 画面の一覧

| 画面 | 使う機能 | 内容 |
| --- | --- | --- |
| 状態と接続 | Lambda での実行 | 動いている関数とバージョン、AWS の各サービスに届くか、読み込んだ設定の名前、無効にした Redmine の設定 |
| メールの送信 | メールの送信のやり直し、プロジェクトごとのアドレス | SES のアカウントの状態、送信元のドメインの確認の状態、送信の上限、送信を止めているアドレス(サプレッションリスト)、テストのメール |
| ジョブ | メールの送信のやり直し(ジョブ全般) | SQS のキューの件数、失敗したジョブの一覧、送り直しと削除 |
| メールの受信 | メールの受信 | 受信のアドレス、受け取ったメールと取り込みの結果、取り込み直し、受信の設定 |
| 添付ファイルの S3 | S3 の添付ファイル | バケットと設定、S3 への読み書きの確認、データベースと S3 の突き合わせ |

Redmine の管理のメニューに「サーバーレス」を足し、5 つの画面をタブで並べます。プラグインの一覧の「設定」からも開けます。

<a id="status-and-connections"></a>

## 状態と接続

| 項目 | 中身 | 取り方 |
| --- | --- | --- |
| 関数 | 関数の名前、役割(`REDMINE_ROLE`)、バージョン、イメージのタグ | Lambda の環境変数(`AWS_LAMBDA_FUNCTION_NAME` など)と、ビルドのときにイメージに入れた値 |
| バージョン | Redmine、Ruby、Rails、自前のプラグイン | Redmine の情報の画面と同じもの |
| 読み込んだ設定 | `/<instance>/env/` の下のパラメーターの名前と、読めたかどうか(値は出さない) | 起動のときに読んだ結果 |
| 無効にした Redmine の設定 | 下の「Lambda で使えない Redmine の設定」の一覧と、今の値 | プラグインが決めた値 |
| 接続の確認 | S3、SQS、SES、SSM、DSQL に届くか、かかった時間 | ボタンを押したときに、軽い API を 1 回ずつ呼ぶ(下の表) |

| 確認する先 | 呼ぶ API |
| --- | --- |
| S3(添付ファイル) | `HeadBucket` |
| SQS | `GetQueueAttributes` |
| SES | `GetAccount` |
| SSM | `GetParametersByPath`(1 件だけ) |
| DSQL | 新しい接続を作り(IAM の認証のトークンを作るところから)、`SELECT 1` を実行する。つないだデータベースのロール(`current_user`)と、今の接続を作ってからの時間(1 時間で切れる)も出す |

- **使い道:** IAM の権限、DSQL のデータベースのロールの結び付け、SSM の設定を変えたあとに、どこまで届くかを画面で確認できます。RDS にして VPC に入れたときは、エンドポイントやセキュリティグループの設定の確認にも使えます([rds.md](https://redmine-kit.github.io/serverless/ja/rds.html))。

<a id="redmine-settings-that-cannot-work-on-lambda"></a>

## Lambda で使えない Redmine の設定

Redmine の標準の設定のうち、Lambda の上では動かないものや、この設計では開けておかないものは、プラグインが無効に固定し、Redmine の設定の画面にもそう表示します。

| 設定(Redmine の画面の名前) | 画面 | プラグインの扱い | 理由 |
| --- | --- | --- | --- |
| 使用するバージョン管理システム(`enabled_scm`) | 管理 › 設定 › リポジトリ | 空に固定する。プロジェクトにリポジトリを作れなくなる | リポジトリを置く場所がない(`/tmp` は環境ごとで、消える)。Git などのコマンドもイメージに入れない |
| コミットを自動取得する(`autofetch_changesets`) | 同上 | 無効に固定する | 同上 |
| リポジトリ管理用のWebサービスを有効にする(`sys_api_enabled`) | 同上 | 無効に固定する | 同上 |
| 受信メール用のWebサービスを有効にする(`mail_handler_api_enabled`) | 管理 › 設定 › 受信メール | 無効に固定する | メールは SES で受けて `redmine-task` が取り込む([mail.md](https://redmine-kit.github.io/serverless/ja/mail.html#receiving))。外から HTTP でメールを送り込める Web サービスを開けない |
| 添付ファイルサイズの上限(`attachment_max_size`) | 管理 › 設定 › ファイル | 変えられる。上限の目安の説明を足す | 画面からのアップロードは、登録のときの SHA256 の計算が 60 秒に収まる大きさまで。REST API の `POST /uploads.json` は 1 MB まで([attachments.md](attachments.md#upload)) |

- **値を固定する:** プラグインが、上の設定の読み出し(`Setting.enabled_scm` など)を差し替えて、決めた値を返します。設定の画面から保存しても、これらの値は変わりません。データベースに古い値が残っていても、使われません。
- **画面に表示する:** Redmine の設定の画面で、上の設定の入力を押せなくし、「サーバーレスの環境では使えません(Redmine Serverless)」と添えます。画面のテンプレートは差し替えず、設定の画面を開いたときだけ、プラグインが小さな JavaScript を読み込んで表示を変えます(Redmine の標準のフック `view_layouts_base_html_head`)。JavaScript が動かなくても、値は上のとおり固定されているので、効き目は変わりません。
- **プロジェクトのモジュール:** バージョン管理システムを選べないので、モジュールの「リポジトリ」を有効にしても、リポジトリは作れません。新しいプロジェクトの既定のモジュール(`default_projects_modules`)からは外しておきます(設定のファイルの `redmine.settings`。[deploy-config.md](https://redmine-kit.github.io/serverless/ja/deploy-config.html))。
- **条件:** Lambda の上(`REDMINE_ROLE` があるとき)だけ固定します。手元のテストや、Lambda でない環境では、Redmine の標準のままです。
- **管理画面の「情報」:** Redmine の標準の確認(ファイルの保存先に書き込めるか、ジョブのキューを既定から変えたか、ImageMagick、Ghostscript、Pandoc など)は、この設計で通る見込みです(保存先は `/tmp/redmine/files`、ジョブは `:sqs`)。

<a id="sending-email"></a>

## メールの送信

| 項目 | 中身 | 取り方 |
| --- | --- | --- |
| アカウントの状態 | 本番での利用(サンドボックスの解除)、送信が有効か、制限の状態 | SES v2 の `GetAccount` |
| 送信の上限 | 24 時間の上限、1 秒あたりの上限、直近 24 時間に送った数 | 同上 |
| 送信元のドメイン | 管理画面の送信元のアドレスのドメインが確認済みか、DKIM の状態 | SES v2 の `GetEmailIdentity` |
| サプレッションリスト | SES が送信を止めているアドレス(バウンスと苦情で登録されたもの)の一覧。Redmine のユーザーのアドレスと突き合わせて表示する | SES v2 の `ListSuppressedDestinations` |
| サプレッションリストからの削除 | ボタンで、アドレスを一覧から外す | SES v2 の `DeleteSuppressedDestination` |
| テストのメール | Redmine の標準の「テストメールを送信」(管理の「設定」の「メール通知」)へのリンク。同じ機能は足さない | — |
| 失敗したメール | 「ジョブ」の画面の、失敗したメールだけの一覧へのリンク | — |

- **サプレッションリストを出す理由:** あるアドレスが一度バウンスすると、SES はそのアドレスへの送信を止めます。Redmine からは送れたように見えるので、「通知が届かない」と言われたときに、ここで確認できるようにします。
- **テストのメール:** Redmine の標準のテストのメールは、画面の要求の中で送る(`deliver_now`)ので、`redmine-web` にも SES の送信の権限を付けます([mail.md](https://redmine-kit.github.io/serverless/ja/mail.html#ses))。

<a id="jobs"></a>

## ジョブ

| 項目 | 中身 | 取り方 |
| --- | --- | --- |
| キューの件数 | 待っているジョブ、実行中のジョブ、時間を置いているジョブ | SQS の `GetQueueAttributes`(`ApproximateNumberOfMessages` など) |
| デッドレターキューの件数 | やり直しを使い切ったジョブの件数 | 同上 |
| 失敗したジョブの一覧 | ジョブの種類(メールのときは、メールの種類と宛先)、エラーの種類とメッセージ、試した回数、最初と最後の時刻 | プラグインのテーブル(下記) |
| 送り直し | 1 件ずつ、または選んだものをまとめて、SQS に積み直す | 記録したジョブの中身から積み直す |
| 削除 | 送り直さない失敗を一覧から消す | — |
| デッドレターキューを戻す | デッドレターキューのジョブを、元のキューに戻す | SQS の `StartMessageMoveTask` |

- **失敗の記録:** ジョブが最後に失敗したとき(やり直しを使い切ったときと、やり直さないエラーのとき)に、プラグインのテーブル(`serverless_job_failures`)に、ジョブの中身(`job.serialize`)とエラーを残します。プラグインの migration で、このテーブルを作ります。データベースに書けなかったときのために、デッドレターキューも残します。
- **送り直しの流れ:** 原因を直してから(たとえば、SES の送信の再開、サプレッションリストからの削除)、送り直しのボタンを押します。メールの送り直しは、[mail.md](https://redmine-kit.github.io/serverless/ja/mail.html#when-sending-fails) にあります。

<a id="receiving-email"></a>

## メールの受信

| 項目 | 中身 | 取り方 |
| --- | --- | --- |
| 受信のアドレス | Redmine のサブドメイン、全体用のアドレス、プロジェクトごとのアドレスの一覧(受けるかどうか、別名) | プラグインの設定と、プロジェクトのメールの設定 |
| MX のレコード | 受信のホスト名の MX が、SES の受信の宛先を向いているか | DNS を引く(Lambda の既定の DNS で、インターネットの名前を引く) |
| 受け取ったメール | 受け取った時刻、差出人、件名、結果(作ったチケット、付けた注記、捨てた理由) | プラグインのテーブル(下記) |
| 取り込み直し | 捨てたメールや失敗したメールを、もう一度取り込む | ジョブを SQS に積み、`redmine-worker` が取り込む |
| 受信の設定 | 全体用のアドレス(`@` の前)、全体用のアドレスに届いたメールの扱い(既定のプロジェクトに入れるか、捨てるか)、プロジェクトごとの送信元を使うか | プラグインの設定(画面で変える)。DMARC が通らないメールは、設定によらず捨てる([mail.md](https://redmine-kit.github.io/serverless/ja/mail.html#spoofing-and-spam)) |

- **取り込みの記録:** `redmine_serverless:receive_mail` が、メールごとの結果(宛先と、当てはめたプロジェクトを含む)を、プラグインのテーブル(`serverless_received_mails`)に残します。メールの本文は残さず、S3 の場所(`inbound/` か `processed/` のキー)を残します。記録は 90 日で消します([security.md](https://redmine-kit.github.io/serverless/ja/security.html#retention-periods))。
- **捨てた理由:** ウイルス、迷惑メール、DMARC が通らない、登録のないアドレス、自動応答、Redmine の取り込みのエラーのどれかを出します。差出人を偽ったメールが来ていないかを、ここで確認できます。
- **取り込み直し:** 画面から `redmine-task` を直接呼ばず、ジョブを SQS に積みます。`redmine-web` に Lambda を呼ぶ権限を持たせずに済みます。
- **受信の設定を画面にする理由:** 既定のプロジェクトを変えるたびにデプロイしなくて済みます。`redmine_serverless:receive_mail` は、実行のたびにデータベースから設定を読みます。

<a id="project-email-settings"></a>

## プロジェクトのメールの設定

プロジェクトの設定に「メール」のタブを足します。プロジェクトごとのアドレス([mail.md](https://redmine-kit.github.io/serverless/ja/mail.html#addresses-per-project))を設定します。

| 項目 | 中身 |
| --- | --- |
| アドレス | `<識別子>@<Redmine のサブドメイン>`。表示だけ |
| メールを受けるか | 受けない(既定)か、受ける |
| 別名 | 識別子とは別のアドレス(`@` の前)。ほかのプロジェクトの識別子、別名、予約した名前と重なると保存できない |
| 既定の値 | 作るチケットのトラッカー、カテゴリー、優先度、担当者、プライベートにするか |
| 登録のないアドレスの扱い | 取り込まない(既定)、匿名のユーザーで受ける、アカウントを作る(Redmine の `unknown_user` の `ignore`、`accept`、`create`) |

- **開ける人:** Redmine の管理者と、プラグインが足すプロジェクトの権限「メールの設定の管理」を持つ人です。
- **登録のないアドレスを受けるとき:** 問い合わせの窓口のように、外の人からのメールを受けるときに使います。迷惑メールが増えるので、DMARC の確認([mail.md](https://redmine-kit.github.io/serverless/ja/mail.html#spoofing-and-spam))を外さないようにします。

<a id="attachments-in-s3"></a>

## 添付ファイルの S3

| 項目 | 中身 | 取り方 |
| --- | --- | --- |
| 設定 | バケットの名前、リージョン、署名付き URL の期限、`/tmp` のキャッシュの大きさ | 環境変数(表示だけ)、プラグインの設定(期限など) |
| 読み書きの確認 | 確認用のオブジェクト(`tmp/healthcheck/<UUID>`)を置いて、読んで、消す | ボタンで `PutObject`、`GetObject`、`DeleteObject` |
| 突き合わせ | データベースの添付ファイルのうち、S3 にないもの。S3 にあるが、どの添付ファイルからも使われていないもの | ボタンで、ジョブとして実行し、結果を画面に出す |
| 直接の送信の確認 | バケットの CORS が、Redmine のドメインからの `POST` を許しているか | `GetBucketCors` |

- **使い道:** 古い Redmine から添付ファイルを移したあと([migration.md](https://redmine-kit.github.io/serverless/ja/migration.html))に、突き合わせで漏れがないかを確認できます。

<a id="permissions"></a>

## 権限

画面のために、`redmine-web` の実行ロールに、SES の状態を読む権限、SQS のキューの件数を読んでデッドレターキューを戻す権限、S3 の CORS を読む権限を足します。突き合わせのジョブのために、`redmine-worker` に S3 の一覧の権限を付けます。詳しくは [iam.md](https://redmine-kit.github.io/serverless/ja/iam.html) にあります。

<a id="tests"></a>

## テスト

画面ごとに、Redmine の機能のテストとシステムのテストを書きます([testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#administration-pages))。

<a id="to-verify"></a>

## 確認すること

- Rails の ActiveJob で、やり直しを使い切ったときと、やり直さないエラーのときに、失敗を記録するのに使える仕組み(`after_discard` など)
- 画面の要求の中で、新しい DSQL の接続を作って確認するのに、どのくらい時間がかかるか
