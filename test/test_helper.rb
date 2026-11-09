# frozen_string_literal: true

# Coverage of the plugin's own files (bin/test sets PLUGIN_COVERAGE for the
# plugin's tests), written as Cobertura XML to coverage/ for Codecov. It starts
# before Redmine loads, so that boot/, lib/ and app/ are counted.
if ENV['PLUGIN_COVERAGE']
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.start do
    root File.expand_path('..', __dir__)
    add_filter '/test/'
    enable_coverage :branch
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end

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
