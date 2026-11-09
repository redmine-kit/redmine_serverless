# frozen_string_literal: true

require_relative '../test_helper'

module RedmineServerless
  class LambdaSettingsTest < ActiveSupport::TestCase
    include RedmineServerless::TestHelper

    def setup
      Setting.enabled_scm = %w[Git Subversion]
      Setting.autofetch_changesets = '1'
      Setting.sys_api_enabled = '1'
      Setting.mail_handler_api_enabled = '1'
    end

    def test_settings_are_fixed_on_lambda
      with_role('web') do
        assert_equal [], Setting.enabled_scm
        assert_not Setting.autofetch_changesets?
        assert_not Setting.sys_api_enabled?
        assert_not Setting.mail_handler_api_enabled?
        assert_equal '0', Setting.sys_api_enabled
      end
    end

    def test_saving_does_not_change_the_fixed_values
      with_role('worker') do
        Setting.enabled_scm = %w[Git]
        Setting.mail_handler_api_enabled = '1'

        assert_equal [], Setting.enabled_scm
        assert_not Setting.mail_handler_api_enabled?
      end
    end

    def test_standard_without_the_role
      with_role(nil) do
        assert_equal %w[Git Subversion], Setting.enabled_scm
        assert Setting.autofetch_changesets?
        assert Setting.sys_api_enabled?
        assert Setting.mail_handler_api_enabled?
      end
    end

    def test_repositories_cannot_be_created_on_lambda
      with_role('web') do
        repository = Repository::Git.new(project: Project.find(3), url: '/tmp/repo.git', identifier: 'lambda')

        assert_not repository.valid?
      end
    end

    def test_the_other_settings_are_untouched
      with_role('web') do
        Setting.app_title = 'Lambda Redmine'

        assert_equal 'Lambda Redmine', Setting.app_title
      end
    end
  end
end
