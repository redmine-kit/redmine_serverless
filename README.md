# Redmine Serverless

A Redmine plugin for running Redmine on AWS Lambda: the Lambda Web Adapter `/events` endpoint, Redmine settings that cannot work on Lambda fixed and shown on screen, and the "Serverless" administration page with the status and connections of the AWS side. It is the plugin of [Serverless](https://github.com/redmine-kit/serverless). Attachments, email, jobs and settings from Parameter Store are the separate plugins [Redmine Serverless S3](https://github.com/redmine-kit/redmine_serverless_s3), [Redmine Serverless SES](https://github.com/redmine-kit/redmine_serverless_ses), [Redmine Serverless SQS](https://github.com/redmine-kit/redmine_serverless_sqs) and [Redmine Serverless SSM](https://github.com/redmine-kit/redmine_serverless_ssm).

[日本語](README.ja.md)

> **Status:** early development. The `/events` middleware, the fixed settings and the "Serverless" administration page are implemented and tested on Redmine 7.0.3.

## Documentation

- Website: https://redmine-kit.github.io/redmine_serverless/ (日本語: https://redmine-kit.github.io/redmine_serverless/ja/)
- Markdown: [docs/README.md](docs/README.md) (日本語: [docs/ja/README.md](docs/ja/README.md)), with [setup](docs/setup.md), [IAM permissions](docs/iam.md) and the [administration pages](docs/admin.md)

## License

Redmine Serverless is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](LICENSE). Not affiliated with the Redmine project.
