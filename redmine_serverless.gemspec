# frozen_string_literal: true

# The plugin as a gem, published to GitHub Packages (.github/workflows/gem.yml).
# The gem holds the plugin's run-time files, so that the installed gem can be
# linked into Redmine's plugins/ (docs/setup.md#installation). The plugin's
# Gemfile is not in it: Redmine's Gemfile would load it again.
Gem::Specification.new do |spec|
  spec.name = 'redmine_serverless'
  spec.version = File.read(File.join(__dir__, 'lib/redmine_serverless.rb'))[/VERSION = '([^']+)'/, 1]
  spec.summary = 'Runs Redmine on AWS Lambda'
  spec.authors = ['Redmine Kit']
  spec.license = 'GPL-2.0-or-later'
  spec.homepage = 'https://github.com/redmine-kit/redmine_serverless'
  spec.required_ruby_version = '>= 4.0'
  spec.files = Dir['{init.rb,LICENSE}', '{app,assets,boot,config,db,lib,help}/**/*']
  # boot/ holds what Bundler loads before Rails initializes; lib/ is Redmine's
  # (autoloaded) and must not be required by Bundler.
  spec.require_paths = ['boot']
  spec.metadata['github_repo'] = 'ssh://github.com/redmine-kit/redmine_serverless'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
