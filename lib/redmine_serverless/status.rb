# frozen_string_literal: true

module RedmineServerless
  # What the "Status" tab shows (docs/admin.md#status-and-connections).
  # No secret values: only names.
  class Status
    def function
      {
        name: ENV.fetch('AWS_LAMBDA_FUNCTION_NAME', nil),
        role: RedmineServerless.role,
        version: ENV.fetch('AWS_LAMBDA_FUNCTION_VERSION', nil),
        memory: ENV.fetch('AWS_LAMBDA_FUNCTION_MEMORY_SIZE', nil),
        region: ENV.fetch('AWS_REGION', nil),
        image: ENV.fetch('REDMINE_IMAGE', nil)
      }
    end

    def versions
      plugins = Redmine::Plugin.all.select { |plugin| plugin.id.to_s.start_with?('redmine_serverless') }
      [['Redmine', Redmine::VERSION.to_s], ['Ruby', RUBY_VERSION], ['Rails', Rails.version]] +
        plugins.map { |plugin| [plugin.name.to_s, plugin.version.to_s] }
    end

    # Names read from SSM Parameter Store at start-up, when Redmine Serverless
    # SSM is installed; nil otherwise.
    def loaded_settings
      RedmineServerlessSsm.loaded if defined?(RedmineServerlessSsm) && RedmineServerlessSsm.respond_to?(:loaded)
    end

    def fixed_settings
      LambdaSettings::FIXED.keys.map { |name| [name, Setting.public_send(name)] }
    end

    # A new connection to the configured database, closed afterwards, so that
    # the check shows whether a connection can be opened now.
    def self.database_check
      db_config = ActiveRecord::Base.connection_db_config
      adapter = db_config.adapter_class.new(db_config.configuration_hash)
      begin
        "#{adapter.adapter_name} #{database_version(adapter)}"
      ensure
        adapter.disconnect!
      end
    end

    # The server's version ("16.4"), which also shows that a query runs.
    def self.database_version(adapter)
      sql = case adapter.adapter_name
            when /postg/i then 'SHOW server_version'
            when /sqlite/i then 'SELECT sqlite_version()'
            else 'SELECT VERSION()'
            end
      adapter.select_value(sql).to_s.split.first
    end
  end
end
