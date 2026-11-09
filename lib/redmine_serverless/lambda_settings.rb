# frozen_string_literal: true

module RedmineServerless
  # Redmine settings that cannot work on Lambda, fixed while REDMINE_ROLE is
  # set (docs/admin.md#redmine-settings-that-cannot-work-on-lambda). Redmine
  # generates these readers on Setting (Setting.define_setting); they are the
  # only Redmine code the plugin replaces. Values saved from the settings page
  # stay in the database and are not used.
  module LambdaSettings
    FIXED = {
      enabled_scm: [],
      autofetch_changesets: '0',
      sys_api_enabled: '0',
      mail_handler_api_enabled: '0'
    }.freeze

    FIXED.each do |name, value|
      define_method(name) { RedmineServerless.lambda? ? value.dup : super() }
      define_method(:"#{name}?") { RedmineServerless.lambda? ? false : super() }
    end

    def self.install
      Setting.singleton_class.prepend(self) unless Setting.singleton_class.include?(self)
    end
  end
end
