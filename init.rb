# frozen_string_literal: true

# Redmine runs this when it prepares the code. The /events middleware and the
# asset setting are in boot/redmine_serverless.rb, which Bundler loads earlier.
Redmine::Plugin.register :redmine_serverless do
  name 'Redmine Serverless'
  author 'Redmine Kit'
  description 'Runs Redmine on AWS Lambda'
  version RedmineServerless::VERSION
  url 'https://github.com/redmine-kit/redmine_serverless'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end

RedmineServerless.setup
