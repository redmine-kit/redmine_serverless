# Setup

What a Redmine needs to use Redmine Serverless: installation, configuration, the AWS resources it expects, IAM permissions and network access. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up with CloudFormation; this page is for setting it up by hand, or for checking what Serverless creates. The plugin is in the design stage, so the details below are the design and are checked when the code is written.

## Requirements

- Redmine 7.0 or later on PostgreSQL.
- On AWS Lambda: a container image with Lambda Web Adapter, as in [Serverless](https://redmine-kit.github.io/serverless/lambda.html#image). Outside Lambda (without `REDMINE_ROLE`), the plugin's features stay off and Redmine behaves as standard.

## Installation

**Getting the plugin:** with Docker, copy it from the plugin's image on ghcr.io, pinned by digest (tags: `main` and `sha-<commit>` for every push to `main`, `v*` for releases):

```dockerfile
COPY --from=ghcr.io/redmine-kit/redmine_serverless:main@sha256:<digest> /redmine_serverless plugins/redmine_serverless/
```

Without Docker, clone the repository (`git clone https://github.com/redmine-kit/redmine_serverless.git plugins/redmine_serverless`) or, once releases are published, extract a release archive into `plugins/redmine_serverless`.

1. Put the plugin in `plugins/redmine_serverless` and run `bundle install` (the plugin's `Gemfile` is loaded by Redmine's).
2. No migration is needed.

## Configuration

| Setting | Where | Contents |
| --- | --- | --- |
| `REDMINE_ROLE` | Environment variable of each function | `web`, `worker` or `task`. Turns on the features for Lambda ([README.md](README.md#features)) |

- **Settings from SSM:** To read settings and secrets from SSM Parameter Store at start-up, use [Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/). With it installed, "Status and connections" shows the names of the parameters read.

## AWS resources

| Resource | Settings |
| --- | --- |
| Lambda functions | Container image functions with `REDMINE_ROLE` set, running Redmine through Lambda Web Adapter ([Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html)) |

## IAM permissions

The permissions the plugin needs, with an example policy, are in [iam.md](iam.md).

## Network

| Destination | API | In a VPC without internet access |
| --- | --- | --- |
| The database | PostgreSQL (the database check on "Status and connections") | A security group rule from the functions to the database port |

## Tests

Redmine's standard plugin tests (`bin/rake redmine:plugins:test NAME=redmine_serverless`). Serverless runs them with its scripts, which take a local checkout of this plugin with `REDMINE_SERVERLESS_DIR` ([Serverless testing.md](https://redmine-kit.github.io/serverless/testing.html#running-on-lambda-redmine_serverless)).

## To verify

- Whether Redmine's settings page can be changed through the hook `view_layouts_base_html_head` alone, without replacing templates ([admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda))
