# Redmine Serverless

Redmine を AWS Lambda で動かすための Redmine のプラグインです。Lambda Web Adapter の `/events`、Lambda で使えない Redmine の設定の固定と画面での表示、失敗したジョブの記録と送り直し、AWS の側の管理画面を持ちます。[Serverless](https://github.com/redmine-kit/serverless) のプラグインです。S3 の添付ファイルと SES でのメールは、別のプラグインの [Redmine Serverless S3](https://github.com/redmine-kit/redmine_serverless_s3) と [Redmine Serverless SES](https://github.com/redmine-kit/redmine_serverless_ses) です。

[English](README.md)

> **状態:** 設計段階です。リポジトリには設計の資料だけがあり、まだ何も実装していません。

<a id="documentation"></a>

## ドキュメント

- Web サイト: https://redmine-kit.github.io/redmine_serverless/ja/ (English: https://redmine-kit.github.io/redmine_serverless/)
- Markdown: [docs/ja/README.md](docs/ja/README.md) (English: [docs/README.md](docs/README.md))。[管理画面](docs/ja/admin.md)があります。

<a id="license"></a>

## ライセンス

Redmine Serverless は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](LICENSE) を参照してください。Redmine projectとは関係ありません。
