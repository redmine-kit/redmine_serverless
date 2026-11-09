# Redmine Serverless

Redmine Serverless (`redmine_serverless`) is a Redmine plugin for running Redmine on AWS Lambda. [Serverless](https://redmine-kit.github.io/serverless/architecture.html) installs it in the Lambda image. It does not modify Redmine's own files and uses only Redmine's standard extension mechanisms. The plugin is in early development (version 0.1.0).

- [Setup](setup.md): requirements, installation, configuration, AWS resources, network, tests
- [IAM permissions](iam.md): permissions, example policy, resource-based policies
- [Administration pages](admin.md): status and connections, Redmine settings that cannot work on Lambda
- [Running on Lambda](#running-on-lambda): `/events`, asset detection, tests

## Features

The plugin keeps Redmine's standard behavior as far as possible and implements only what running on Lambda needs. Each feature has a condition that enables it. A feature whose conditions are not met behaves as standard Redmine.

| Feature | Contents | Enabled when | Page |
| --- | --- | --- | --- |
| Running on Lambda | A Rack middleware that returns 204 for Lambda Web Adapter's `/events`, a setting that stops automatic asset compilation, Redmine settings that cannot work on Lambda fixed to disabled and shown on screen | `REDMINE_ROLE` is set | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |
| Administration pages | The "Status and connections" tab under the shared "Serverless" menu, with the checks of the other plugins | Administrators | [admin.md](admin.md) |

The other features for AWS are separate plugins, which also work outside Lambda:

| Plugin | Contents |
| --- | --- |
| [Redmine Serverless S3](https://redmine-kit.github.io/redmine_serverless_s3/) | Attachments in S3: uploads and downloads through CloudFront with signed URLs, the `/tmp` cache |
| [Redmine Serverless SES](https://redmine-kit.github.io/redmine_serverless_ses/) | Email through SES: retries of sending by error type, receiving and importing, addresses per project |
| [Redmine Serverless SQS](https://redmine-kit.github.io/redmine_serverless_sqs/) | Jobs on SQS: the settings of `aws-activejob-sqs`, job failure records, resending |
| [Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/) | Settings and secrets from SSM Parameter Store, read before Rails starts |

All of them put their administration pages under one "Serverless" item of Redmine's administration menu, as tabs of one page, whichever are installed ([admin.md](admin.md#the-serverless-menu)). With this plugin installed, their checks also join its connection check.

- **Code structure:** `boot/redmine_serverless.rb` holds what must be in place before Rails initializes (the `/events` middleware and the asset setting); Bundler loads it, because the plugin is also a gem ([setup.md](setup.md#installation)). The rest is in `lib/redmine_serverless/` and `app/`, which Redmine loads, and `init.rb` turns it on.
- **Gems:** The plugin calls no AWS API itself, so it needs no AWS SDK gem.
- **Tests:** Tests are written for each piece of replaced code, using Redmine's standard mechanism (`rake redmine:plugins:test`) ([setup.md](setup.md#tests)).
- **Migrations:** None.

## Running on Lambda

On Lambda (when `REDMINE_ROLE` is set), the plugin adapts Redmine as follows. [Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html) has the image and the functions.

| What | How | Why |
| --- | --- | --- |
| `/events` | A Rack middleware at the top of the stack (registered by `boot/`) answers `/events` with 204, before anything touches the database or a session. Other paths pass | Lambda Web Adapter passes events that do not come through the function URL (such as warming) to Puma as a POST to `/events` (`AWS_LWA_PASS_THROUGH_PATH`). Without the role, `/events` is an ordinary path (404) |
| Asset detection | `config.assets.redmine_detect_update` is `false`, set in `boot/` with `after_initialize`, which runs before Redmine's own check | `production.rb` sets it to `true`, and Redmine then writes outdated assets to `public/assets` at start-up. On Lambda the file system is read-only and the image has the assets compiled |
| Redmine settings that cannot work | Fixed to disabled and shown on the settings page | [admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda) |

### Tests

| Target | What is checked |
| --- | --- |
| `/events` | 204 without SQL and without a session cookie; other paths pass; 404 without the role; the middleware is the first one |
| Asset detection | `false` in a new process with `REDMINE_ROLE`, unchanged without it |
| Fixed settings | The readers return the fixed values on Lambda, saving does not change them, Redmine's standard behavior without the role; the settings page shows the inputs disabled |
| The replaced code | The SHA-256 of `Setting.define_setting` in Redmine is compared, so that an upgrade of Redmine that changes it is noticed |
| Administration pages | Only administrators; no secrets on the page; the database check and its failure; one menu item |

## Sponsors

<Sponsors><a href="https://localstack.cloud">LocalStack</a></Sponsors>

## License

Redmine Serverless is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](../LICENSE). An unofficial Redmine plugin.
