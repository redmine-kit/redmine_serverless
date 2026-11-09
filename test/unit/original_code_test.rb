# frozen_string_literal: true

require_relative '../test_helper'
require 'digest'

module RedmineServerless
  # The plugin replaces the readers that Setting.define_setting writes
  # (LambdaSettings). If an upgrade of Redmine changes that method, this test
  # fails, so that the replacement is reviewed.
  class OriginalCodeTest < ActiveSupport::TestCase
    DEFINE_SETTING = '0384523872c1238e3a0c8f3f2911d75af5b0c50416c22d80456b51d9c80d1569'

    def method_source(method)
      file, line = method.source_location
      lines = File.readlines(file)[(line - 1)..]
      indent = lines.first[/\A */]
      last = lines.index { |l| l == "#{indent}end\n" }
      lines[0..last].join
    end

    def test_setting_define_setting_is_unchanged
      assert_equal DEFINE_SETTING, Digest::SHA256.hexdigest(method_source(Setting.method(:define_setting)))
    end
  end
end
