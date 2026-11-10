# frozen_string_literal: true

# Running Redmine on AWS Lambda (docs/README.md). The features are on only
# when REDMINE_ROLE is set (web, worker or task), as on Lambda.
module RedmineServerless
  VERSION = '0.2.0'
  ROLES = %w[web worker task].freeze

  def self.role
    ENV.fetch('REDMINE_ROLE', '').presence
  end

  def self.lambda?
    role.present?
  end

  # Called from init.rb, on every code reload.
  def self.setup
    LambdaSettings.install
    # Loaded here so that the listener registers itself in every environment.
    Hooks.name
    RedmineServerlessAdmin.register_tab(:status, label: :label_serverless_status,
                                                 url: { controller: 'serverless_status', action: 'index' },
                                                 position: 10)
    RedmineServerlessAdmin.register_check(:database, label: :label_serverless_check_database) do
      Status.database_check
    end
  end
end
