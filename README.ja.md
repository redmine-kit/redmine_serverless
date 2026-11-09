# Redmine Serverless

[![CI](https://img.shields.io/github/actions/workflow/status/redmine-kit/redmine_serverless/ci.yml?branch=main&label=CI)](https://github.com/redmine-kit/redmine_serverless/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/codecov/c/github/redmine-kit/redmine_serverless?label=Coverage)](https://codecov.io/gh/redmine-kit/redmine_serverless)
[![License](https://img.shields.io/github/license/redmine-kit/redmine_serverless?label=License)](LICENSE)

Redmine を AWS Lambda で動かすための Redmine のプラグインです。Lambda Web Adapter の `/events`、Lambda で使えない Redmine の設定の固定と画面での表示、AWS の側の状態と接続を見る「Serverless」の管理画面を持ちます。[Serverless](https://github.com/redmine-kit/serverless) のプラグインです。添付ファイル、メール、ジョブ、Parameter Store の設定は、別のプラグインの [Redmine Serverless S3](https://github.com/redmine-kit/redmine_serverless_s3)、[Redmine Serverless SES](https://github.com/redmine-kit/redmine_serverless_ses)、[Redmine Serverless SQS](https://github.com/redmine-kit/redmine_serverless_sqs)、[Redmine Serverless SSM](https://github.com/redmine-kit/redmine_serverless_ssm) です。

[English](README.md)

> **状態:** 開発の初期です。`/events` のミドルウェア、設定の固定、「Serverless」の管理画面を実装し、Redmine 7.0.3 でテストしています。

<a id="documentation"></a>

## ドキュメント

- Web サイト: https://redmine-kit.github.io/redmine_serverless/ja/ (English: https://redmine-kit.github.io/redmine_serverless/)
- Markdown: [docs/ja/README.md](docs/ja/README.md) (English: [docs/README.md](docs/README.md))。[準備](docs/ja/setup.md)、[IAM の権限](docs/ja/iam.md)と[管理画面](docs/ja/admin.md)があります。

<a id="license"></a>

## ライセンス

Redmine Serverless は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](LICENSE) を参照してください。Redmine projectとは関係ありません。
