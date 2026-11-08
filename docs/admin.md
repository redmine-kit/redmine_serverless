# Administration pages

This is the design of the pages that the plugin `redmine_serverless` adds to Redmine's administration menu. The "Feature used" column for each page refers to the features inside the plugin ([the plugin's features](README.md#features)). Pages for features that are not in use are not shown. The pages let you check and operate sending and receiving email, jobs, attachments in S3, and the state of connections to AWS from within Redmine.

The specifications in this page were checked against official information and the Redmine 7.0.3 source as of 2026-11-08. Sources are in [sources.md](https://redmine-kit.github.io/redmine-serverless/sources.html).

## Approach

- **Administrators only:** Every page can be opened only by Redmine administrators. It uses the same check as Redmine's administration pages (`require_admin`).
- **No secrets shown:** Values in SSM Parameter Store, `SECRET_KEY_BASE` and database authentication tokens are not shown. Only parameter names and whether they could be read are shown.
- **Call AWS APIs only when needed:** So that opening a page does not call many APIs, state is cached for 1 minute, and heavy checks run as jobs when a button is pressed.
- **Non-secret settings are changed on the page:** Non-secret settings, such as options for receiving email, are plugin settings (Redmine's `Setting.plugin_*`, stored in the database) and can be changed on the page. Values set by the infrastructure, such as AWS resource names, stay as environment variables and are only displayed.
- **Operations are logged:** Operations such as resending and deleting are written to Redmine's log with who did what and when.

## List of pages

| Page | Feature used | Contents |
| --- | --- | --- |
| Status and connections | Running on Lambda | The running function and its version, whether each AWS service is reachable, names of loaded settings, disabled Redmine settings |
| Sending email | Retrying email sending, addresses per project | SES account status, verification status of the sender domain, sending limits, addresses blocked from sending (suppression list), test email |
| Jobs | Retrying email sending (jobs in general) | Number of messages in the SQS queues, list of failed jobs, resend and delete |
| Receiving email | Receiving email | Receiving addresses, received email and import results, re-import, receiving settings |
| Attachments in S3 | Attachments in S3 | Bucket and settings, S3 read/write check, reconciliation between the database and S3 |

A "Serverless" item is added to Redmine's administration menu, with the 5 pages as tabs. They can also be opened from "Configure" in the plugin list.

## Status and connections

| Item | Contents | Source |
| --- | --- | --- |
| Function | Function name, role (`REDMINE_ROLE`), version, image tag | Lambda environment variables (`AWS_LAMBDA_FUNCTION_NAME`, etc.) and values put into the image at build time |
| Versions | Redmine, Ruby, Rails, the project's own plugin | The same as Redmine's information page |
| Loaded settings | Names of parameters under `/<instance>/env/` and whether they could be read (values are not shown) | The result of reading them at start-up |
| Disabled Redmine settings | The list in "Redmine settings that cannot work on Lambda" below and their current values | Values set by the plugin |
| Connection check | Whether S3, SQS, SES, SSM and DSQL are reachable, and how long it took | When the button is pressed, call one light API for each (table below) |

| Target | API called |
| --- | --- |
| S3 (attachments) | `HeadBucket` |
| SQS | `GetQueueAttributes` |
| SES | `GetAccount` |
| SSM | `GetParametersByPath` (1 item only) |
| DSQL | Open a new connection (starting from creating the IAM authentication token) and run `SELECT 1`. Also show the database role connected as (`current_user`) and the time since the current connection was opened (it expires after 1 hour) |

- **Use:** After changing IAM permissions, DSQL database role bindings or SSM settings, you can check on the page how far requests reach. When using RDS inside a VPC, it also helps check endpoint and security group settings ([rds.md](https://redmine-kit.github.io/redmine-serverless/rds.html)).

## Redmine settings that cannot work on Lambda

Standard Redmine settings that do not work on Lambda, or that this design does not leave open, are fixed to disabled by the plugin, and Redmine's settings page shows this.

| Setting (name in the Redmine UI) | Page | How the plugin handles it | Reason |
| --- | --- | --- | --- |
| Enabled SCM (`enabled_scm`) | Administration › Settings › Repositories | Fixed to empty. Projects can no longer have repositories | There is nowhere to keep repositories (`/tmp` is per execution environment and disappears). Commands such as Git are not in the image either |
| Fetch commits automatically (`autofetch_changesets`) | Same as above | Fixed to disabled | Same as above |
| Enable WS for repository management (`sys_api_enabled`) | Same as above | Fixed to disabled | Same as above |
| Enable WS for incoming emails (`mail_handler_api_enabled`) | Administration › Settings › Incoming emails | Fixed to disabled | Email is received by SES and imported by `redmine-task` ([mail.md](https://redmine-kit.github.io/redmine-serverless/mail.html#receiving)). A web service that lets anyone push email in over HTTP is not left open |
| Maximum attachment size (`attachment_max_size`) | Administration › Settings › Files | Can be changed. A note on the practical limit is added | Uploads from the UI are limited to a size whose SHA256 can be computed within 60 seconds at registration. The REST API `POST /uploads.json` is limited to 1 MB ([attachments.md](attachments.md#upload)) |

- **Fixing the values:** The plugin replaces the readers of the settings above (`Setting.enabled_scm`, etc.) so they return the fixed values. Saving from the settings page does not change these values. Old values left in the database are not used.
- **Showing it on the page:** On Redmine's settings page, the inputs for the settings above are disabled, with the note "Not available in a serverless environment (redmine_serverless)". The page templates are not replaced. Only when the settings page is opened does the plugin load a small JavaScript file that changes the display (Redmine's standard hook `view_layouts_base_html_head`). Even if the JavaScript does not run, the values are fixed as above, so the effect is the same.
- **Project modules:** Because no SCM can be selected, enabling the "Repository" module does not let anyone create a repository. It is removed from the default modules for new projects (`default_projects_modules`) (`redmine.settings` in the configuration file; [deploy-config.md](https://redmine-kit.github.io/redmine-serverless/deploy-config.html)).
- **Condition:** The values are fixed only on Lambda (when `REDMINE_ROLE` is set). In local tests and environments other than Lambda, standard Redmine behavior applies.
- **"Information" on the administration page:** Redmine's standard checks (whether the file storage directory is writable, whether the job queue was changed from the default, ImageMagick, Ghostscript, Pandoc, etc.) are expected to pass in this design (storage is `/tmp/redmine/files`, jobs use `:sqs`).

## Sending email

| Item | Contents | Source |
| --- | --- | --- |
| Account status | Production access (out of the sandbox), whether sending is enabled, enforcement status | SES v2 `GetAccount` |
| Sending limits | 24-hour limit, per-second limit, number sent in the last 24 hours | Same as above |
| Sender domain | Whether the domain of the emission address in the administration settings is verified, DKIM status | SES v2 `GetEmailIdentity` |
| Suppression list | List of addresses SES has stopped sending to (added because of bounces and complaints), matched against Redmine users' addresses | SES v2 `ListSuppressedDestinations` |
| Removing from the suppression list | A button removes an address from the list | SES v2 `DeleteSuppressedDestination` |
| Test email | A link to Redmine's standard "Send a test email" (in "Email notifications" under Administration › Settings). The same feature is not added | — |
| Failed email | A link to the list of failed email only on the "Jobs" page | — |

- **Why show the suppression list:** Once an address bounces, SES stops sending to it. From Redmine it looks as if the email was sent, so when someone says "notifications do not arrive", this page lets you check.
- **Test email:** Redmine's standard test email is sent within the page request (`deliver_now`), so `redmine-web` is also given permission to send through SES ([mail.md](https://redmine-kit.github.io/redmine-serverless/mail.html#ses)).

## Jobs

| Item | Contents | Source |
| --- | --- | --- |
| Queue counts | Jobs waiting, jobs running, jobs delayed | SQS `GetQueueAttributes` (`ApproximateNumberOfMessages`, etc.) |
| Dead-letter queue count | Number of jobs that used up their retries | Same as above |
| List of failed jobs | Job type (for email, the mail type and recipients), error type and message, number of attempts, first and last time | The plugin's table (below) |
| Resend | Put jobs back on SQS one at a time, or the selected ones together | Re-enqueue from the recorded job contents |
| Delete | Remove failures that will not be resent from the list | — |
| Redrive the dead-letter queue | Move jobs in the dead-letter queue back to the original queue | SQS `StartMessageMoveTask` |

- **Recording failures:** When a job fails for the last time (when retries are used up, and on errors that are not retried), the plugin stores the job contents (`job.serialize`) and the error in its table (`serverless_job_failures`). The plugin's migration creates this table. The dead-letter queue is also kept in case writing to the database fails.
- **Resend flow:** Fix the cause first (for example, resume SES sending, or remove an address from the suppression list), then press the resend button. Resending email is described in [mail.md](https://redmine-kit.github.io/redmine-serverless/mail.html#when-sending-fails).

## Receiving email

| Item | Contents | Source |
| --- | --- | --- |
| Receiving addresses | Redmine's subdomain, the global address, and the list of addresses per project (whether they receive, aliases) | Plugin settings and project email settings |
| MX record | Whether the MX of the receiving host name points to the SES receiving endpoint | DNS lookup (internet names are resolved with Lambda's default DNS) |
| Received email | Time received, sender, subject, result (issue created, note added, reason dropped) | The plugin's table (below) |
| Re-import | Import dropped or failed email again | Put a job on SQS; `redmine-worker` imports it |
| Receiving settings | The global address (the part before `@`), how to handle email sent to the global address (put it in the default project, or drop it), whether to use per-project senders | Plugin settings (changed on the page). Email that fails DMARC is dropped regardless of settings ([mail.md](https://redmine-kit.github.io/redmine-serverless/mail.html#spoofing-and-spam)) |

- **Import records:** `redmine_serverless:receive_mail` stores the result for each email (including the recipient and the project it was matched to) in the plugin's table (`serverless_received_mails`). The email body is not stored; its location in S3 (the key in `inbound/` or `processed/`) is. Records are deleted after 90 days ([security.md](https://redmine-kit.github.io/redmine-serverless/security.html#retention-periods)).
- **Reasons for dropping:** One of: virus, spam, DMARC failure, unregistered address, auto-reply, or a Redmine import error. This page lets you check whether email with a forged sender is arriving.
- **Re-import:** The page does not call `redmine-task` directly; it puts a job on SQS. This way `redmine-web` does not need permission to invoke Lambda.
- **Why receiving settings are on the page:** You do not have to deploy each time you change the default project. `redmine_serverless:receive_mail` reads the settings from the database on every run.

## Project email settings

An "Email" tab is added to project settings. It configures the address per project ([mail.md](https://redmine-kit.github.io/redmine-serverless/mail.html#addresses-per-project)).

| Item | Contents |
| --- | --- |
| Address | `<identifier>@<Redmine's subdomain>`. Display only |
| Whether to receive email | Do not receive (default) or receive |
| Alias | An address other than the identifier (the part before `@`). It cannot be saved if it matches another project's identifier or alias, or a reserved name |
| Default values | Tracker, category, priority, assignee of created issues, and whether they are private |
| Handling unregistered addresses | Do not import (default), accept as the anonymous user, or create an account (Redmine's `unknown_user` values `ignore`, `accept`, `create`) |

- **Who can open it:** Redmine administrators and people with the project permission "Manage email settings" that the plugin adds.
- **When accepting unregistered addresses:** Use this to receive email from outside people, such as for a contact desk. Spam increases, so do not turn off the DMARC check ([mail.md](https://redmine-kit.github.io/redmine-serverless/mail.html#spoofing-and-spam)).

## Attachments in S3

| Item | Contents | Source |
| --- | --- | --- |
| Settings | Bucket name, Region, presigned URL expiry, size of the `/tmp` cache | Environment variables (display only), plugin settings (expiry, etc.) |
| Read/write check | Put a check object (`tmp/healthcheck/<UUID>`), read it, and delete it | A button runs `PutObject`, `GetObject`, `DeleteObject` |
| Reconciliation | Attachments in the database that are not in S3. Objects in S3 not used by any attachment | A button runs it as a job and shows the result on the page |
| Direct upload check | Whether the bucket CORS allows `POST` from Redmine's domain | `GetBucketCors` |

- **Use:** After moving attachments from an older Redmine ([migration.md](https://redmine-kit.github.io/redmine-serverless/migration.html)), reconciliation lets you check that nothing is missing.

## Permissions

For these pages, the execution role of `redmine-web` gets permissions to read SES status, to read SQS queue counts and redrive the dead-letter queue, and to read S3 CORS. For the reconciliation job, `redmine-worker` gets permission to list S3. Details are in [iam.md](https://redmine-kit.github.io/redmine-serverless/iam.html).

## Tests

Each page has Redmine functional tests and system tests ([testing.md](https://redmine-kit.github.io/redmine-serverless/testing.html#administration-pages)).

## To verify

- Which mechanism in Rails ActiveJob can be used to record failures when retries are used up and on errors that are not retried (`after_discard`, etc.)
- How long it takes to open a new DSQL connection and check it within a page request
