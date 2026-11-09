# 状態と接続

「管理」›「Serverless」›「状態と接続」には、Redmine が AWS Lambda でどう動いているかを表示します。関数とその役割、バージョン、「SSM Parameter Store から読み込んだ設定」(名前だけで、値は表示しません)、「Lambda で固定している Redmine の設定」です。

「接続を確認する」を押すと、データベースと、インストールしたプラグインが使う AWS のサービスへの接続を 1 回ずつ確認し、「OK」または「失敗」と詳細を表示します。このページを開けるのは管理者だけです。

Lambda で固定している Redmine の設定(リポジトリの自動取得、リポジトリとメールの受信の Web サービス)は、Lambda では動かないため、「管理」›「設定」で無効として表示されます。

詳しくは [Redmine Serverless の管理画面](https://redmine-kit.github.io/redmine_serverless/ja/admin.html) を参照してください。
