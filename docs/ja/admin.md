# 管理画面

Redmine Serverless が Redmine の管理のメニューに足す画面の設計です。画面の名前の「使用する機能」は、その画面が使用するプラグインの機能です([機能の一覧](README.md#features))。使っていない機能の画面は出しません。AWS への接続の状態を Redmine の画面で確認し、ジョブを操作できるようにします。[Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/ja/admin.html) と [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/ja/admin.html) を入れると、それぞれの画面がここのタブに加わります。

この資料の仕様は、2026-11-08 時点の公式の情報と、Redmine 7.0.3 のソースで確認したものです。出典は [sources.md](https://redmine-kit.github.io/serverless/ja/sources.html) にあります。

<a id="approach"></a>

## 方針

- **管理者だけ:** どの画面も、Redmine の管理者だけが開けます。Redmine の管理の画面と同じ確認(`require_admin`)を使います。
- **秘密の値は出さない:** SSM Parameter Store の値、`SECRET_KEY_BASE`、データベースのパスワードは、画面に出しません。パラメーターの名前と、読めたかどうかだけを出します。
- **AWS の API は必要なときだけ呼ぶ:** 画面を開いただけで多くの API を呼ばないよう、状態は 1 分だけキャッシュし、重い確認はボタンを押したときにジョブで行います。
- **秘密でない設定は画面で変える:** 秘密でない設定は、プラグインの設定(Redmine の `Setting.plugin_*`、データベースに入る)にし、画面で変えられるようにします。AWS のリソースの名前など、インフラで決まる値は、環境変数のまま表示だけします。
- **操作は記録する:** 送り直しや削除などの操作は、Redmine のログに、誰がいつ何をしたかを残します。

<a id="list-of-pages"></a>

## 画面の一覧

| 画面 | 使用する機能 | 内容 |
| --- | --- | --- |
| 状態と接続 | Lambda での実行 | 動いている関数とバージョン、データベースと AWS の各サービスに届くか、読み込んだ設定の名前、無効にした Redmine の設定 |
| ジョブ | ジョブの失敗の記録 | SQS のキューの件数、失敗したジョブの一覧、送り直しと削除 |
| メールの送信、メールの受信 | [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/ja/admin.html) | そのプラグインを入れたときに加わる |
| 添付ファイルの S3 | [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/ja/admin.html) | そのプラグインを入れたときに加わる |

Redmine の管理のメニューに「サーバーレス」を足し、画面をタブで並べます。プラグインの一覧の「設定」からも開けます。

<a id="status-and-connections"></a>

## 状態と接続

| 項目 | 中身 | 取り方 |
| --- | --- | --- |
| 関数 | 関数の名前、役割(`REDMINE_ROLE`)、バージョン、イメージのタグ | Lambda の環境変数(`AWS_LAMBDA_FUNCTION_NAME` など)と、ビルドのときにイメージに入れた値 |
| バージョン | Redmine、Ruby、Rails、入れている Redmine Serverless のプラグイン | Redmine の情報の画面と同じもの |
| 読み込んだ設定 | `/<instance>/env/` の下のパラメーターの名前と、読めたかどうか(値は出さない) | 起動のときに読んだ結果 |
| 無効にした Redmine の設定 | 下の「Lambda で使えない Redmine の設定」の一覧と、今の値 | プラグインが決めた値 |
| 接続の確認 | データベース、SQS、SSM に届くか、かかった時間 | ボタンを押したときに、軽い呼び出しを 1 回ずつ行う(下の表) |

| 確認する先 | 呼ぶ API |
| --- | --- |
| データベース | 設定した PostgreSQL のデータベース(RDS for PostgreSQL など)に新しい接続を作り、`SELECT 1` を実行する。つないだデータベースのユーザー(`current_user`)も出す |
| SQS | `GetQueueAttributes` |
| SSM | `GetParametersByPath`(1 件だけ) |
| S3、SES | Redmine Serverless S3(`HeadBucket`)と Redmine Serverless SES(`GetAccount`)を入れたときに加わる |

- **使い道:** IAM の権限、ネットワークの設定、SSM の設定を変えたあとに、どこまで届くかを画面で確認できます。Lambda を VPC に入れたときは、VPC エンドポイントやセキュリティグループの設定の確認にも使えます。

<a id="redmine-settings-that-cannot-work-on-lambda"></a>

## Lambda で使えない Redmine の設定

Redmine の標準の設定のうち、Lambda の上では動かないものや、この設計では開けておかないものは、プラグインが無効に固定し、Redmine の設定の画面にもそう表示します。

| 設定(Redmine の画面の名前) | 画面 | プラグインの扱い | 理由 |
| --- | --- | --- | --- |
| 使用するバージョン管理システム(`enabled_scm`) | 管理 › 設定 › リポジトリ | 空に固定する。プロジェクトにリポジトリを作れなくなる | リポジトリを置く場所がない(`/tmp` は環境ごとで、消える)。Git などのコマンドもイメージに入れない |
| コミットを自動取得する(`autofetch_changesets`) | 同上 | 無効に固定する | 同上 |
| リポジトリ管理用のWebサービスを有効にする(`sys_api_enabled`) | 同上 | 無効に固定する | 同上 |
| 受信メール用のWebサービスを有効にする(`mail_handler_api_enabled`) | 管理 › 設定 › 受信メール | 無効に固定する | メールは SES で受けて `redmine-task` が取り込む([mail.md](https://redmine-kit.github.io/serverless/ja/mail.html#receiving)、[Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/ja/))。外から HTTP でメールを送り込める Web サービスを開けない |

- **値を固定する:** プラグインが、上の設定の読み出し(`Setting.enabled_scm`、`Setting.autofetch_changesets?`、`Setting.sys_api_enabled?`、`Setting.mail_handler_api_enabled?`)を差し替えて、決めた値を返します。プラグインが Redmine の処理を差し替えるのはここだけです。Redmine を上げるときは、これらの読み出しが変わっていないかを確認します。設定の画面から保存しても、これらの値は変わりません。データベースに古い値が残っていても、使われません。
- **画面に表示する:** Redmine の設定の画面で、上の設定の入力を押せなくし、「サーバーレスの環境では使えません(Redmine Serverless)」と添えます。画面のテンプレートは差し替えず、設定の画面を開いたときだけ、プラグインが小さな JavaScript を読み込んで表示を変えます(Redmine の標準のフック `view_layouts_base_html_head`)。JavaScript が動かなくても、値は上のとおり固定されているので、効き目は変わりません。
- **プロジェクトのモジュール:** バージョン管理システムを選べないので、モジュールの「リポジトリ」を有効にしても、リポジトリは作れません。新しいプロジェクトの既定のモジュール(`default_projects_modules`)からは外しておきます(設定のファイルの `redmine.settings`。[deploy-config.md](https://redmine-kit.github.io/serverless/ja/deploy-config.html))。
- **条件:** Lambda の上(`REDMINE_ROLE` があるとき)だけ固定します。手元のテストや、Lambda でない環境では、Redmine の標準のままです。
- **管理画面の「情報」:** Redmine の標準の確認(ファイルの保存先に書き込めるか、ジョブのキューを既定から変えたか、ImageMagick、Ghostscript、Pandoc など)は、Serverless で通る見込みです(保存先は `/tmp/redmine/files`、ジョブは `:sqs`)。

<a id="jobs"></a>

## ジョブ

| 項目 | 中身 | 取り方 |
| --- | --- | --- |
| キューの件数 | 待っているジョブ、実行中のジョブ、時間を置いているジョブ | SQS の `GetQueueAttributes`(`ApproximateNumberOfMessages` など) |
| デッドレターキューの件数 | やり直しを使い切ったジョブの件数 | 同上 |
| 失敗したジョブの一覧 | ジョブの種類(メールのときは、メールの種類と宛先。失敗したメールだけの一覧も出せる)、エラーの種類とメッセージ、試した回数、最初と最後の時刻 | プラグインのテーブル(下記) |
| 送り直し | 1 件ずつ、または選んだものをまとめて、SQS に積み直す | 記録したジョブの中身から積み直す |
| 削除 | 送り直さない失敗を一覧から消す | — |
| デッドレターキューを戻す | デッドレターキューのジョブを、元のキューに戻す | SQS の `StartMessageMoveTask` |

- **失敗の記録:** ジョブが最後に失敗したとき(やり直しを使い切ったときと、やり直さないエラーのとき)に、プラグインのテーブル(`serverless_job_failures`)に、ジョブの中身(`job.serialize`)とエラーを残します。プラグインの migration で、このテーブルを作ります。データベースに書けなかったときのために、デッドレターキューも残します。
- **送り直しの流れ:** 原因を直してから(たとえば、SES の送信の再開、サプレッションリストからの削除)、送り直しのボタンを押します。メールの送り直しは、[mail.md](https://redmine-kit.github.io/serverless/ja/mail.html#when-sending-fails) にあります。SES のどのエラーをやり直すかは、[Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/ja/) が決めます。

<a id="permissions"></a>

## 権限

画面のために、画面の要求のロールに、SQS のキューの件数を読む権限、ジョブを送り直す権限、デッドレターキューを戻す権限を足します。一覧とポリシーの例は [setup.md](setup.md#iam-permissions) にあります。

<a id="tests"></a>

## テスト

画面ごとに、Redmine の機能のテストとシステムのテストを書きます([testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#administration-pages))。

<a id="to-verify"></a>

## 確認すること

- Rails の ActiveJob で、やり直しを使い切ったときと、やり直さないエラーのときに、失敗を記録するのに使える仕組み(`after_discard` など)
