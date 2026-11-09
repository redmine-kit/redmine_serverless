# Redmine Serverless

Redmine Serverless (`redmine_serverless`) is a Redmine plugin for running Redmine on AWS Lambda. [Serverless](https://redmine-kit.github.io/serverless/architecture.html) installs it in the Lambda image. It does not modify Redmine's own files and uses only Redmine's standard extension mechanisms. The plugin is in the design stage, and only the documentation exists.

- [Setup](setup.md): requirements, installation, configuration, AWS resources, IAM permissions, network, tests
- [Administration pages](admin.md): status and connections, Redmine settings that cannot work on Lambda

## Features

The plugin keeps Redmine's standard behavior as far as possible and implements only what running on Lambda needs. Each feature has a condition that enables it. A feature whose conditions are not met behaves as standard Redmine.

| Feature | Contents | Enabled when | Page |
| --- | --- | --- | --- |
| Running on Lambda | A Rack middleware that returns 204 for Lambda Web Adapter's `/events`, a setting that stops automatic asset compilation, Redmine settings that cannot work on Lambda fixed to disabled and shown on screen | `REDMINE_ROLE` is set | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |
| Administration pages | The "Serverless" page: status and connections, with the tabs and checks of the other plugins | Administrators | [admin.md](admin.md) |

The other features for AWS are separate plugins, which also work outside Lambda:

| Plugin | Contents |
| --- | --- |
| [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/) | Attachments in S3: uploads and downloads through CloudFront with signed URLs, the `/tmp` cache |
| [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/) | Email through SES: retries of sending by error type, receiving and importing, addresses per project |
| [Redmine Serverless SQS](https://redmine-kit.github.io/redmine_serverless_sqs/) | Jobs on SQS: the settings of `aws-activejob-sqs`, job failure records, resending |
| [Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/) | Settings and secrets from SSM Parameter Store, read before Rails starts |

When those plugins are installed, their administration pages appear as tabs of this plugin's "Serverless" page, and their checks join its connection check.

- **Code structure:** Inside the plugin, each feature has its own directory (under `lib/redmine_serverless/`), and features connect to each other only through defined entry points.
- **Gems:** The plugin calls no AWS API itself, so it needs no AWS SDK gem.
- **Tests:** Tests are written for each piece of replaced code, using Redmine's standard mechanism (`rake redmine:plugins:test`) ([setup.md](setup.md#tests)).
- **Migrations:** None.
