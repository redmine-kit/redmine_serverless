# frozen_string_literal: true

require_relative '../test_helper'
require 'open3'

# Redmine writes changed assets to public/assets after initialization unless
# config.assets.redmine_detect_update is false. Checked in a new process,
# because the setting is read once at start-up.
module RedmineServerless
  class AssetsSettingTest < ActiveSupport::TestCase
    def detect_update(role)
      env = { 'REDMINE_ROLE' => role, 'RAILS_ENV' => 'test' }
      script = 'print Rails.application.config.assets.redmine_detect_update.inspect'
      out, status = Open3.capture2(env, 'bin/rails', 'runner', script, chdir: Rails.root.to_s)
      assert status.success?, out
      out.lines.last.to_s.strip
    end

    def test_off_on_lambda
      assert_equal 'false', detect_update('web')
    end

    def test_untouched_without_the_role
      assert_not_equal 'false', detect_update('')
    end
  end
end
