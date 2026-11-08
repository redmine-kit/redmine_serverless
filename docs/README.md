# Redmine Serverless

Redmine Serverless (`redmine_serverless`) is a Redmine plugin for running Redmine on AWS serverless services (Lambda and AWS managed services). [redmine-kit/serverless](https://redmine-kit.github.io/serverless/architecture.html) installs it in the Lambda image. It does not modify Redmine's own files and uses only Redmine's standard extension mechanisms. The plugin is in the design stage, and only the documentation exists.

- [S3 attachments](attachments.md): storage, uploads, downloads, cache
- [Administration pages](admin.md): status and connections, mail sending, jobs, mail receiving, S3 attachments

## Features

The plugin keeps Redmine's standard behavior as far as possible and implements only what is needed to run serverless. Each feature has a condition that enables it. A feature whose conditions are not met behaves as standard Redmine. S3 attachments can also be used outside Lambda.

| Feature | Contents | Kind | Enabled when | Page |
| --- | --- | --- | --- | --- |
| S3 attachments | Storing and deleting, uploads to S3 (presigned POST), redirects to presigned URLs (downloads and thumbnails), the `/tmp` cache, CSV import files, zip files for downloading all attachments | Needed for serverless (no writable disk, the 6 MB limit) | S3 bucket settings (environment variables) exist | [attachments.md](attachments.md) |
| Running on Lambda | A Rack middleware that returns 204 for Lambda Web Adapter's `/events`, a setting that stops automatic asset compilation, Redmine settings that cannot work on Lambda fixed to disabled and shown on screen ([admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda)) | Needed for serverless | `REDMINE_ROLE` exists | [lambda.md](https://redmine-kit.github.io/serverless/lambda.html) |
| Retrying mail sending | `raise_delivery_errors` in `redmine-worker`, retries by error type, failure records | Needed for serverless (jobs go through SQS and another function sends the mail, so failures are not visible on screen) | `REDMINE_ROLE=worker` | [mail.md](https://redmine-kit.github.io/serverless/mail.html#when-sending-fails) |
| Mail receiving | Importing mail received by SES (the rake task `redmine_serverless:receive_mail`, which uses Redmine's standard `MailHandler` inside), spoofing and spam checks, import records | Needed for serverless (there is no IMAP inbox; SES receives the mail) | Receiving settings exist | [mail.md](https://redmine-kit.github.io/serverless/mail.html#importing) |
| Addresses per project | Receiving address and sender per project, a global address, a "Mail" tab in project settings | Not in standard Redmine. Standard Redmine has one sender, and projects are selected by subaddress (`redmine+identifier@…`) | Enabled in the plugin settings. When disabled, same as standard Redmine | [mail.md](https://redmine-kit.github.io/serverless/mail.html#addresses-per-project) |
| Administration pages | Status and connections, mail sending (SES status), jobs, mail receiving, S3 attachments | Needed to operate serverless (see AWS status from Redmine). Pages that standard Redmine already has (such as test mail) are not added | Administrators. Tabs for unused features are not shown | [admin.md](admin.md) |

- **Code structure:** Inside the plugin, each feature has its own directory (under `lib/redmine_serverless/`), and features connect to each other only through defined entry points.
- **Gems:** Gems the plugin uses (such as `aws-sdk-s3`) go in the plugin's `Gemfile`. Redmine's `Gemfile` also loads `plugins/*/Gemfile`.
- **Tests:** Tests are written for each piece of replaced code, using Redmine's standard mechanism (`rake redmine:plugins:test`) ([testing.md](https://redmine-kit.github.io/serverless/testing.html#plugin-tests)).
- **Migrations:** Add tables for failed job records (`serverless_job_failures`), received mail records (`serverless_received_mails`) and project mail settings (`serverless_project_mail_settings`) ([admin.md](admin.md)). Deployment also runs `redmine:plugins:migrate`.
