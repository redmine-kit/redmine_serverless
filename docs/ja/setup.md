# 準備

Redmine Serverless を使う Redmine に要るもの(インストール、設定、前提にする AWS のリソース、IAM の権限、ネットワーク)です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作ります。このページは、手で用意するときや、Serverless が作るものを確認するときのためのものです。

<a id="requirements"></a>

## 前提

- PostgreSQL の上の Redmine 7.0 以降。
- AWS Lambda では、[Serverless](https://redmine-kit.github.io/serverless/ja/lambda.html#image) と同じく、Lambda Web Adapter を入れたコンテナイメージ。Lambda 以外(`REDMINE_ROLE` がないとき)では、プラグインの機能は動かず、Redmine は標準のままに動きます。

<a id="installation"></a>

## インストール

1. プラグインを、Redmine 7.0 の `plugins/redmine_serverless` に置きます。下の gem か、このリポジトリのチェックアウトです。
2. プラグインを gem として `Gemfile.local` に足し、インストールします。

   ```sh
   bundle install
   ```

   こうすると、Bundler が、Rails の初期化より前に `boot/redmine_serverless.rb` を読み込みます。`/events` のミドルウェアとアセットの設定は、そのときまでに要り、Redmine がプラグインを読み込む(`init.rb`)のでは遅すぎるからです。チェックアウトなら、パスで足します。

   ```ruby
   # Redmine の Gemfile.local
   gem 'redmine_serverless', path: 'plugins/redmine_serverless'
   ```

3. migration は要りません。

<a id="gem"></a>

### gem

バージョンのタグ(`v*`)ごとに、プラグインを gem として GitHub Packages(`https://rubygems.pkg.github.com/redmine-kit`)に公開します(`.github/workflows/gem.yml`)。gem は、動かすためのファイル(`init.rb`、`boot/`、`lib/`、`app/`、`config/`、`LICENSE`)を持ちます。プラグインの `Gemfile` は入れません。Redmine は `plugins/` のプラグインだけを読み込むので、インストールした gem をそこにリンクします。

```ruby
# Redmine の Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_serverless'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <ユーザー>:<トークン>   # か、変数 BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_serverless)" plugins/redmine_serverless
```

- **アクセス:** GitHub Packages からインストールするには、公開のパッケージでも、`read:packages` の権限を持つ GitHub のトークンが要ります。ほかのリポジトリのワークフローは、パッケージの設定(「Manage Actions access」)でそのリポジトリに Read を与えると、自分の `GITHUB_TOKEN`(`packages: read`)で読めます。

<a id="configuration"></a>

## 設定

| キー | 説明 | パラメーター |
| --- | --- | --- |
| `REDMINE_ROLE` | Lambda のための機能を有効にする([README.md](README.md#features)) | Lambda では必須。関数ごとに `web`、`worker`、`task` のどれか。なければ機能は無効 |

- **SSM の設定:** 起動のときに SSM Parameter Store から設定と秘密の値を読むには、[Redmine Serverless SSM](https://redmine-kit.github.io/redmine_serverless_ssm/ja/) を使います。それを入れると、「状態と接続」に、読んだパラメーターの名前が出ます。

<a id="aws-resources"></a>

## AWS のリソース

| リソース | 設定 |
| --- | --- |
| Lambda の関数 | `REDMINE_ROLE` を設定し、Lambda Web Adapter で Redmine を動かす、コンテナイメージの関数([Serverless の lambda.md](https://redmine-kit.github.io/serverless/ja/lambda.html)) |

<a id="iam-permissions"></a>

## IAM の権限

プラグインに要る権限と例のポリシーは、[iam.md](iam.md) にあります。

<a id="network"></a>

## ネットワーク

| 行き先 | API | インターネットに出られない VPC の中では |
| --- | --- | --- |
| データベース | PostgreSQL(「状態と接続」のデータベースの確認) | 関数からデータベースのポートへの、セキュリティグループの規則 |

<a id="tests"></a>

## テスト

テストは `test/` にあり、Redmine の標準のしくみで、Docker の中の Redmine 7.0.3 と PostgreSQL 16 で動かします。`bin/test` は、プラグインのテストのあと、差し替えたコードのまわりの Redmine 本体のテスト(設定、リポジトリ、`sys`、メールの受信、管理)を動かします。`bin/test --redmine` は、プラグインを入れた状態で Redmine 本体のすべてのテストを動かします。CI はこちらです。Serverless も、自分のイメージでプラグインのテストを動かします([Serverless の testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#running-on-lambda-redmine_serverless))。

プラグインのテストは、プラグイン自身のファイルのカバレッジ(SimpleCov。Cobertura の XML の `coverage/coverage.xml`)も書きます。CI は、それを [Codecov](https://codecov.io/gh/redmine-kit/redmine_serverless) に送ります。

```sh
bin/test            # プラグインのテストと、そのまわりの Redmine のテスト
bin/test --redmine  # Redmine のすべてのテストも
bin/lint            # RuboCop
bin/services --down # PostgreSQL を止める
```

<a id="to-verify"></a>

## 確認すること

- 今はありません。2026-11-09 に Redmine 7.0.3 で確認しました。テンプレートを差し替えずに、フック `view_layouts_base_html_head` だけで、設定の画面の入力を無効にできます([admin.md](admin.md#redmine-settings-that-cannot-work-on-lambda))。
