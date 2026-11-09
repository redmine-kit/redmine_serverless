# IAM permissions

The plugin itself calls no AWS API, so it needs no permissions of its own. Lambda's own permissions (logs, running in a VPC) are in [Serverless iam.md](https://redmine-kit.github.io/serverless/iam.html).

## Permissions

| Action | Resource | Why |
| --- | --- | --- |
| None | — | The checks on "Status and connections" for S3, SES, SQS and SSM are added by those plugins and use the permissions on their IAM pages: [S3](https://redmine-kit.github.io/redmine_serverless_s3/iam.html), [SES](https://redmine-kit.github.io/redmine_serverless_ses/iam.html), [SQS](https://redmine-kit.github.io/redmine_serverless_sqs/iam.html), [SSM](https://redmine-kit.github.io/redmine_serverless_ssm/iam.html) |

## Example policy

None.

## Resource-based policies

None.

## Not checked yet

Nothing.
