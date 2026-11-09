# Administration pages

This is the design of the pages that Redmine Serverless adds to Redmine's administration menu. The "Feature used" column for each page refers to the features inside the plugin ([the plugin's features](README.md#features)). Pages for features that are not in use are not shown. The pages let you check the state of connections to AWS and operate jobs from within Redmine. [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/admin.html) and [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/admin.html) add their pages as tabs here when they are installed.

The specifications in this page were checked against official information and the Redmine 7.0.3 source as of 2026-11-08. Sources are in [sources.md](https://redmine-kit.github.io/serverless/sources.html).

## Approach

- **Administrators only:** Every page can be opened only by Redmine administrators. It uses the same check as Redmine's administration pages (`require_admin`).
- **No secrets shown:** Values in SSM Parameter Store, `SECRET_KEY_BASE` and the database password are not shown. Only parameter names and whether they could be read are shown.
- **Call AWS APIs only when needed:** So that opening a page does not call many APIs, state is cached for 1 minute, and heavy checks run as jobs when a button is pressed.
- **Non-secret settings are changed on the page:** Non-secret settings are plugin settings (Redmine's `Setting.plugin_*`, stored in the database) and can be changed on the page. Values set by the infrastructure, such as AWS resource names, stay as environment variables and are only displayed.
- **Operations are logged:** Operations such as resending and deleting are written to Redmine's log with who did what and when.

## List of pages

| Page | Feature used | Contents |
| --- | --- | --- |
| Status and connections | Running on Lambda | The running function and its version, whether the database and each AWS service are reachable, names of loaded settings, disabled Redmine settings |
| Jobs | Job failure records | Number of messages in the SQS queues, list of failed jobs, resend and delete |
| Sending email, Receiving email | [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/admin.html) | Added by that plugin when it is installed |
| Attachments in S3 | [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/admin.html) | Added by that plugin when it is installed |

A "Serverless" item is added to Redmine's administration menu, with the pages as tabs. They can also be opened from "Configure" in the plugin list.

## Status and connections

| Item | Contents | Source |
| --- | --- | --- |
| Function | Function name, role (`REDMINE_ROLE`), version, image tag | Lambda environment variables (`AWS_LAMBDA_FUNCTION_NAME`, etc.) and values put into the image at build time |
| Versions | Redmine, Ruby, Rails, the installed Redmine Serverless plugins | The same as Redmine's information page |
| Loaded settings | Names of parameters under `/<instance>/env/` and whether they could be read (values are not shown) | The result of reading them at start-up |
| Disabled Redmine settings | The list in "Redmine settings that cannot work on Lambda" below and their current values | Values set by the plugin |
| Connection check | Whether the database, SQS and SSM are reachable, and how long it took | When the button is pressed, make one light call to each (table below) |

| Target | API called |
| --- | --- |
| Database | Open a new connection to the configured PostgreSQL database (such as RDS for PostgreSQL) and run `SELECT 1`. Also show the database user connected as (`current_user`) |
| SQS | `GetQueueAttributes` |
| SSM | `GetParametersByPath` (1 item only) |
| S3, SES | Added by Redmine Serverless S3 (`HeadBucket`) and Redmine Serverless SES (`GetAccount`) when they are installed |

- **Use:** After changing IAM permissions, network settings or SSM settings, you can check on the page how far requests reach. With Lambda inside a VPC, it also helps check VPC endpoint and security group settings.

## Redmine settings that cannot work on Lambda

Standard Redmine settings that do not work on Lambda, or that this design does not leave open, are fixed to disabled by the plugin, and Redmine's settings page shows this.

| Setting (name in the Redmine UI) | Page | How the plugin handles it | Reason |
| --- | --- | --- | --- |
| Enabled SCM (`enabled_scm`) | Administration › Settings › Repositories | Fixed to empty. Projects can no longer have repositories | There is nowhere to keep repositories (`/tmp` is per execution environment and disappears). Commands such as Git are not in the image either |
| Fetch commits automatically (`autofetch_changesets`) | Same as above | Fixed to disabled | Same as above |
| Enable WS for repository management (`sys_api_enabled`) | Same as above | Fixed to disabled | Same as above |
| Enable WS for incoming emails (`mail_handler_api_enabled`) | Administration › Settings › Incoming emails | Fixed to disabled | Email is received by SES and imported by `redmine-task` ([mail.md](https://redmine-kit.github.io/serverless/mail.html#receiving); [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/)). A web service that lets anyone push email in over HTTP is not left open |

- **Fixing the values:** The plugin replaces the readers of the settings above (`Setting.enabled_scm`, `Setting.autofetch_changesets?`, `Setting.sys_api_enabled?`, `Setting.mail_handler_api_enabled?`) so they return the fixed values. This is the plugin's only replacement of Redmine code; when Redmine is upgraded, check that these readers have not changed. Saving from the settings page does not change these values. Old values left in the database are not used.
- **Showing it on the page:** On Redmine's settings page, the inputs for the settings above are disabled, with the note "Not available in a serverless environment (Redmine Serverless)". The page templates are not replaced. Only when the settings page is opened does the plugin load a small JavaScript file that changes the display (Redmine's standard hook `view_layouts_base_html_head`). Even if the JavaScript does not run, the values are fixed as above, so the effect is the same.
- **Project modules:** Because no SCM can be selected, enabling the "Repository" module does not let anyone create a repository. It is removed from the default modules for new projects (`default_projects_modules`) (`redmine.settings` in the configuration file; [deploy-config.md](https://redmine-kit.github.io/serverless/deploy-config.html)).
- **Condition:** The values are fixed only on Lambda (when `REDMINE_ROLE` is set). In local tests and environments other than Lambda, standard Redmine behavior applies.
- **"Information" on the administration page:** Redmine's standard checks (whether the file storage directory is writable, whether the job queue was changed from the default, ImageMagick, Ghostscript, Pandoc, etc.) are expected to pass in Serverless (storage is `/tmp/redmine/files`, jobs use `:sqs`).

## Jobs

| Item | Contents | Source |
| --- | --- | --- |
| Queue counts | Jobs waiting, jobs running, jobs delayed | SQS `GetQueueAttributes` (`ApproximateNumberOfMessages`, etc.) |
| Dead-letter queue count | Number of jobs that used up their retries | Same as above |
| List of failed jobs | Job type (for email, the mail type and recipients; failed email can be listed on its own), error type and message, number of attempts, first and last time | The plugin's table (below) |
| Resend | Put jobs back on SQS one at a time, or the selected ones together | Re-enqueue from the recorded job contents |
| Delete | Remove failures that will not be resent from the list | — |
| Redrive the dead-letter queue | Move jobs in the dead-letter queue back to the original queue | SQS `StartMessageMoveTask` |

- **Recording failures:** When a job fails for the last time (when retries are used up, and on errors that are not retried), the plugin stores the job contents (`job.serialize`) and the error in its table (`serverless_job_failures`). The plugin's migration creates this table. The dead-letter queue is also kept in case writing to the database fails.
- **Resend flow:** Fix the cause first (for example, resume SES sending, or remove an address from the suppression list), then press the resend button. Resending email is described in [mail.md](https://redmine-kit.github.io/serverless/mail.html#when-sending-fails); which SES errors are retried is decided by [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/).

## Permissions

For these pages, the execution role of `redmine-web` gets permissions to read SQS queue counts and to redrive the dead-letter queue. Details are in [iam.md](https://redmine-kit.github.io/serverless/iam.html).

## Tests

Each page has Redmine functional tests and system tests ([testing.md](https://redmine-kit.github.io/serverless/testing.html#administration-pages)).

## To verify

- Which mechanism in Rails ActiveJob can be used to record failures when retries are used up and on errors that are not retried (`after_discard`, etc.)
