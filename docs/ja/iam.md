# IAM の権限

プラグインは自分では AWS の API を呼ばないので、自分の権限は要りません。Lambda そのものの権限(ログ、VPC の中での実行)は、[Serverless の iam.md](https://redmine-kit.github.io/serverless/ja/iam.html) にあります。

<a id="permissions"></a>

## 権限

| 操作 | 対象 | 理由 |
| --- | --- | --- |
| なし | — | 「ステータス」の S3、SES、SQS、SSM の確認は、それぞれのプラグインが追加し、それぞれの IAM の権限のページにある権限を使う([S3](https://redmine-kit.github.io/redmine_serverless_s3/ja/iam.html)、[SES](https://redmine-kit.github.io/redmine_serverless_ses/ja/iam.html)、[SQS](https://redmine-kit.github.io/redmine_serverless_sqs/ja/iam.html)、[SSM](https://redmine-kit.github.io/redmine_serverless_ssm/ja/iam.html)) |

<a id="example-policy"></a>

## ポリシーの例

ありません。

<a id="resource-based-policies"></a>

## リソースベースのポリシー

ありません。

<a id="not-checked-yet"></a>

## 未確認の事項

ありません。
