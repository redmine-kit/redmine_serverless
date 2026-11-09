# frozen_string_literal: true

require File.expand_path('../../../test/test_helper', __dir__)

module RedmineServerless
  module TestHelper
    # Runs the block as on Lambda (REDMINE_ROLE set), or without the role.
    def with_role(role)
      saved = ENV.fetch('REDMINE_ROLE', nil)
      role ? ENV['REDMINE_ROLE'] = role : ENV.delete('REDMINE_ROLE')
      yield
    ensure
      saved ? ENV['REDMINE_ROLE'] = saved : ENV.delete('REDMINE_ROLE')
    end
  end
end
