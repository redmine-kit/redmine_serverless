# Setup

What a Redmine needs to use Redmine Serverless: installation, configuration, the AWS resources it expects, IAM permissions and network access. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up with CloudFormation; this page is for setting it up by hand, or for checking what Serverless creates.

## Requirements

- Redmine 7.0 or later on PostgreSQL.
- On AWS Lambda: a container image with Lambda Web Adapter, as in [Serverless](https://redmine-kit.github.io/serverless/lambda.html#image). Outside Lambda (without `REDMINE_ROLE`), the plugin's features stay off and Redmine behaves as standard.

## Installation

1. Get the plugin into `plugins/redmine_serverless` of Redmine 7.0: the gem below, or a checkout of this repository.
2. Add the plugin to `Gemfile.local` as a gem, and install it:

   ```sh
   bundle install
   ```

   Bundler then loads `boot/redmine_serverless.rb` before Rails initializes: the `/events` middleware and the asset setting must be in place by then, and Redmine's own loading of plugins (`init.rb`) comes too late for them. With a checkout, add it by path:

   ```ruby
   # Redmine's Gemfile.local
   gem 'redmine_serverless', path: 'plugins/redmine_serverless'
   ```

3. No migration is needed.

### Gem

Each version tag (`v*`) publishes the plugin as a gem to GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`; `.github/workflows/gem.yml`). The gem holds the run-time files (`init.rb`, `boot/`, `lib/`, `app/`, `config/`, `LICENSE`); the plugin's `Gemfile` is not in it. Redmine loads plugins only from `plugins/`, so the installed gem is linked there:

```ruby
# Redmine's Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_serverless'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <user>:<token>   # or BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_serverless)" plugins/redmine_serverless
```

Installing from GitHub Packages needs a GitHub token with `read:packages`, even for a public package. A workflow of another repository reads it with its `GITHUB_TOKEN` (`packages: read`) once the package's settings ("Manage Actions access") give that repository Read.

## Configuration

| Key | Description | Parameter |
| --- | --- | --- |
| `REDMINE_ROLE` | Turns on the features for Lambda ([README.md](README.md#features)) | Required on Lambda. Per function: `web`, `worker` or `task`. Without it, the features stay off |

To read settings and secrets from SSM Parameter Store at start-up, use [Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/). With it installed, the "Status" tab shows the names of the parameters read.

## AWS resources

| Resource | Settings |
| --- | --- |
| Lambda functions | Container image functions with `REDMINE_ROLE` set, running Redmine through Lambda Web Adapter ([Serverless lambda.md](https://redmine-kit.github.io/serverless/lambda.html)) |

## IAM permissions

The permissions the plugin needs, with an example policy, are in [iam.md](iam.md).

## Network

| Destination | API | In a VPC without internet access |
| --- | --- | --- |
| The database | PostgreSQL (the database test on the "Status" tab) | A security group rule from the functions to the database port |

## Tests

The tests are in `test/` and run with Redmine's standard mechanism, in Redmine 7.0.3 on PostgreSQL 16 in Docker. `bin/test` runs the plugin's tests, then Redmine's own tests around the replaced code (settings, repositories, `sys`, incoming email, administration); `bin/test --redmine` runs every Redmine test with the plugin installed, as the CI does. Serverless also runs the plugin's tests in its image ([Serverless testing.md](https://redmine-kit.github.io/serverless/testing.html#running-on-lambda-redmine_serverless)).

The plugin's tests also write the coverage of the plugin's own files (SimpleCov, Cobertura XML in `coverage/coverage.xml`), which CI uploads to [Codecov](https://codecov.io/gh/redmine-kit/redmine_serverless).

```sh
bin/test            # the plugin's tests and Redmine's tests around them
bin/test --redmine  # with every Redmine test
bin/lint            # RuboCop
bin/services --down # stops PostgreSQL
```

## To verify

- Nothing for now. Checked on 2026-11-09 with Redmine 7.0.3: the hook `view_layouts_base_html_head` alone disables the inputs on the settings page, without replacing templates ([admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda)).
