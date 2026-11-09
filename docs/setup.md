# Setup

What a Redmine needs to use Redmine Serverless: installation, configuration, the AWS resources it expects, IAM permissions and network access. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up with CloudFormation; this page is for setting it up by hand, or for checking what Serverless creates. The plugin is in the design stage, so the details below are the design and are checked when the code is written.

## Requirements

- Redmine 7.0 or later on PostgreSQL.
- On AWS Lambda: a container image with Lambda Web Adapter, as in [Serverless](https://redmine-kit.github.io/serverless/lambda.html#image). Outside Lambda (without `REDMINE_ROLE`), the plugin's features stay off and Redmine behaves as standard.
- Jobs through SQS with the official AWS gem `aws-activejob-sqs` (the job failure records and the "Jobs" page work with it).

## Installation

1. Put the plugin in `plugins/redmine_serverless` and run `bundle install` (the plugin's `Gemfile` is loaded by Redmine's).
2. Run `bin/rake redmine:plugins:migrate`. It creates the table of failed job records (`serverless_job_failures`).

## Configuration

| Setting | Where | Contents |
| --- | --- | --- |
| `REDMINE_ROLE` | Environment variable of each function | `web`, `worker` or `task`. Turns on the features for Lambda ([README.md](README.md#features)) |
| `REDMINE_JOBS_QUEUE_URL` | Environment variable | The URL of the job queue, which the SQS adapter and the "Jobs" page use |
| Job queue adapter | `config/additional_environment.rb` | `config.active_job.queue_adapter = :sqs` when `REDMINE_ROLE` is set, and the queues in `config/aws_active_job_sqs.yml` ([Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html#background-jobs)) |

- **The dead-letter queue:** How the plugin finds the dead-letter queue of the job queue for the "Jobs" page is decided when the code is written (not decided yet).
- **Settings from SSM:** To read settings and secrets from SSM Parameter Store at start-up, use [Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/). The connection check of the "Status and connections" page also calls SSM.

## AWS resources

| Resource | Settings |
| --- | --- |
| SQS job queue | A standard queue. Visibility timeout longer than the timeout of the function that runs jobs. A redrive policy to a dead-letter queue after 3 receives |
| SQS dead-letter queue | Receives the jobs that failed 3 times. The "Jobs" page moves them back with `StartMessageMoveTask` |
| Function that runs jobs | `REDMINE_ROLE=worker`, with an SQS event source mapping on the job queue (batch size 1) ([Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html#background-jobs)) |

## IAM permissions

The plugin's own calls to AWS. Lambda's own permissions (logs, running in a VPC) and the permissions of the other plugins are not included; [Serverless iam.md](https://redmine-kit.github.io/serverless/iam.html) has the full roles.

| Permission | Resource | Role | Use |
| --- | --- | --- | --- |
| `sqs:GetQueueAttributes` | The job queue and its dead-letter queue | Web requests | Queue counts on the "Jobs" page, and the SQS check on "Status and connections" |
| `sqs:SendMessage` | The job queue | Web requests | Resending recorded jobs from the "Jobs" page (enqueuing jobs in general needs it too) |
| `sqs:StartMessageMoveTask`, `sqs:ListMessageMoveTasks` | The dead-letter queue | Web requests | Moving the dead-letter queue back to the job queue |
| `ssm:GetParametersByPath` | `arn:aws:ssm:<region>:<account>:parameter/<instance>/env` and below it | Web requests | The SSM check on "Status and connections" (1 item) |

Example policy for the role of web requests:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "JobsPage",
      "Effect": "Allow",
      "Action": ["sqs:GetQueueAttributes", "sqs:SendMessage"],
      "Resource": [
        "arn:aws:sqs:<region>:<account>:<instance>-jobs",
        "arn:aws:sqs:<region>:<account>:<instance>-jobs-dlq"
      ]
    },
    {
      "Sid": "Redrive",
      "Effect": "Allow",
      "Action": ["sqs:StartMessageMoveTask", "sqs:ListMessageMoveTasks"],
      "Resource": "arn:aws:sqs:<region>:<account>:<instance>-jobs-dlq"
    },
    {
      "Sid": "ConnectionCheck",
      "Effect": "Allow",
      "Action": "ssm:GetParametersByPath",
      "Resource": [
        "arn:aws:ssm:<region>:<account>:parameter/<instance>/env",
        "arn:aws:ssm:<region>:<account>:parameter/<instance>/env/*"
      ]
    }
  ]
}
```

- **Moving messages:** Whether the caller of `StartMessageMoveTask` also needs `sqs:ReceiveMessage` and `sqs:DeleteMessage` on the dead-letter queue and `sqs:SendMessage` on the job queue is checked when building (not checked yet).

## Network

| Destination | API | In a VPC without internet access |
| --- | --- | --- |
| SQS | `GetQueueAttributes`, `SendMessage`, `StartMessageMoveTask` | Interface endpoint `com.amazonaws.<region>.sqs` |
| SSM | `GetParametersByPath` (connection check) | Interface endpoint `com.amazonaws.<region>.ssm` |
| The database | PostgreSQL (connection check) | A security group rule from the functions to the database port |

## Tests

Redmine's standard plugin tests (`bin/rake redmine:plugins:test NAME=redmine_serverless`). Serverless runs them with its scripts, which take a local checkout of this plugin with `REDMINE_SERVERLESS_DIR` ([Serverless testing.md](https://redmine-kit.github.io/serverless/testing.html#running-on-lambda-redmine_serverless)).
