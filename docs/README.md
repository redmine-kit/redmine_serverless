# Redmine Serverless

Redmine Serverless (`redmine_serverless`) is a Redmine plugin for running Redmine on AWS Lambda. [Serverless](https://redmine-kit.github.io/serverless/architecture.html) installs it in the Lambda image. It does not modify Redmine's own files and uses only Redmine's standard extension mechanisms. The plugin is in the design stage, and only the documentation exists.

- [Administration pages](admin.md): status and connections, settings that cannot work on Lambda, jobs

## Features

The plugin keeps Redmine's standard behavior as far as possible and implements only what running on Lambda needs. Each feature has a condition that enables it. A feature whose conditions are not met behaves as standard Redmine.

| Feature | Contents | Kind | Enabled when | Page |
| --- | --- | --- | --- | --- |
| Running on Lambda | A Rack middleware that returns 204 for Lambda Web Adapter's `/events`, a setting that stops automatic asset compilation, Redmine settings that cannot work on Lambda fixed to disabled and shown on screen ([admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda)) | Needed on Lambda | `REDMINE_ROLE` exists | [lambda.md](https://redmine-kit.github.io/serverless/lambda.html) |
| Job failure records | Jobs that fail for the last time (retries used up, or errors that are not retried) are recorded with their contents and can be resent | Needed on Lambda (jobs go through SQS and another function runs them, so failures are not visible on screen) | `REDMINE_ROLE=worker` | [admin.md](admin.md#jobs) |
| Administration pages | Status and connections, jobs | Needed to operate Redmine on Lambda (see AWS status from Redmine) | Administrators | [admin.md](admin.md) |

The other features for AWS are separate plugins, which also work outside Lambda:

| Plugin | Contents |
| --- | --- |
| [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/) | Attachments in S3: direct uploads, presigned URLs for downloads and thumbnails, the `/tmp` cache |
| [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/) | Email through SES: retries of sending by error type, receiving and importing, addresses per project |

When those plugins are installed, their administration pages appear as tabs of this plugin's "Serverless" page, and their checks join its connection check.

- **Code structure:** Inside the plugin, each feature has its own directory (under `lib/redmine_serverless/`), and features connect to each other only through defined entry points.
- **Gems:** Gems the plugin uses (such as `aws-sdk-sqs`) go in the plugin's `Gemfile`. Redmine's `Gemfile` also loads `plugins/*/Gemfile`.
- **Tests:** Tests are written for each piece of replaced code, using Redmine's standard mechanism (`rake redmine:plugins:test`) ([testing.md](https://redmine-kit.github.io/serverless/testing.html#plugin-tests)).
- **Migrations:** Add a table for failed job records (`serverless_job_failures`) ([admin.md](admin.md#jobs)). Deployment also runs `redmine:plugins:migrate`.
