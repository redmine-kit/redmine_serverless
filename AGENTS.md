# AGENTS.md

Guidelines for people and coding agents working in this repository. See [README.md](README.md) for an overview and [docs/](docs/README.md) for the design.

## What this project does

Redmine Serverless (`redmine_serverless`) is a Redmine plugin for running Redmine on AWS Lambda. It is used by [Serverless](https://github.com/redmine-kit/serverless), which runs Redmine on AWS Lambda. Attachments, email, jobs and settings from Parameter Store are separate plugins ([redmine_serverless_s3](https://github.com/redmine-kit/redmine_serverless_s3), [redmine_serverless_ses](https://github.com/redmine-kit/redmine_serverless_ses), [redmine_serverless_sqs](https://github.com/redmine-kit/redmine_serverless_sqs), [redmine_serverless_ssm](https://github.com/redmine-kit/redmine_serverless_ssm)). It is in early development.

## Rules

- **Redmine's extension points only:** do not edit Redmine's own files. Keep Redmine's standard behaviour wherever possible, and write only what running serverless needs.
- **Features can be turned on separately:** each feature has the condition that turns it on; without it, Redmine behaves as standard.
- **Replaced code:** the plugin replaces only the readers of the settings that cannot work on Lambda ([admin.md](docs/admin.md#redmine-settings-that-cannot-work-on-lambda)). When Redmine is upgraded, check that the original code has not changed.
- **Tests:** replaced and added code has tests, run with Redmine's own mechanism (`bin/test` runs them in Docker; [setup.md](docs/setup.md#tests)). The test plan is in Serverless ([testing.md](https://github.com/redmine-kit/serverless/blob/main/docs/testing.md#plugin-tests)).
- **Code layout:** `boot/` holds what must be in place before Rails initializes (Bundler loads it; module `RedmineServerlessBoot`), `lib/` and `app/` the rest (Redmine autoloads them; `init.rb` calls `RedmineServerless.setup`).
- **Shared files:** `lib/redmine_serverless_admin.rb`, `app/controllers/serverless_admin_controller.rb` and `app/views/serverless_admin/_tabs.html.erb` are the same in every Redmine Serverless plugin. Change them in all plugins together and raise `SHARED_VERSION`.
- **No secrets in the repository.**

## Documentation

- **Two languages.** English is the source (`README.md`, `docs/`); the Japanese translation is `README.ja.md` and `docs/ja/`, with the same file names. Change both together.
- **Layout.** The READMEs stay short. The details go in `docs/`, published at https://redmine-kit.github.io/redmine_serverless/ with [redmine-kit/docs-skeleton](https://github.com/redmine-kit/docs-skeleton). `docs/README.md` has the overview and the features, `docs/setup.md` the sections Requirements, Installation, Configuration, AWS resources, IAM permissions, Network, Tests and To verify, in this order (the same in every Redmine Serverless plugin; IAM permissions there is one line that points to `docs/iam.md`), `docs/iam.md` the sections Permissions, Example policy, Resource-based policies and Not checked yet. Links to the documentation of Serverless are absolute GitHub URLs.
- **Anchors in Japanese.** Put `<a id="..."></a>` with the English heading's anchor before each Japanese heading.
- **Facts.** State only what has been checked, with the date and the source. Mark what has not been checked yet.
- **Japanese wording.** Plain, precise Japanese. Keep established technical terms. Do not use "版" for a version, write "通知" rather than "知らせ", "確認" rather than "確かめ", and "インストール" rather than "入れ方".

## Commits

- English, imperative mood, 72 characters or fewer in the first line, no trailing period.
- One purpose per commit.
- Do not rewrite pushed history.
