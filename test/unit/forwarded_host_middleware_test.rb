# frozen_string_literal: true

require_relative '../test_helper'

module RedmineServerless
  # The middleware in front of Rails' host authorization with config.hosts set
  # to the Redmine domain only, as on Lambda (REDMINE_HOST). Requests come as
  # CloudFront sends them: the function URL's host name in Host.
  class ForwardedHostMiddlewareTest < ActiveSupport::TestCase
    include RedmineServerless::TestHelper

    DOMAIN = 'redmine.example.com'
    FUNCTION_URL_HOST = 'abcdefghijklmnopqrstuvwxyz012345.lambda-url.ap-northeast-1.on.aws'

    def setup
      app = ->(env) { [200, {}, [ActionDispatch::Request.new(env).url]] }
      @stack = RedmineServerlessBoot::ForwardedHostMiddleware.new(ActionDispatch::HostAuthorization.new(app, [DOMAIN]))
    end

    def request(headers = {})
      env = Rack::MockRequest.env_for('/login', { 'HTTP_HOST' => FUNCTION_URL_HOST,
                                                  'HTTP_X_FORWARDED_PROTO' => 'https' }.merge(headers))
      Rack::MockResponse.new(*@stack.call(env))
    end

    def test_the_forwarded_host_is_accepted_and_used_for_urls
      response = with_role('web') { request('HTTP_X_FORWARDED_HOST' => DOMAIN) }

      assert_equal 200, response.status
      assert_equal "https://#{DOMAIN}/login", response.body
    end

    def test_the_last_forwarded_host_counts
      response = with_role('web') { request('HTTP_X_FORWARDED_HOST' => "evil.example.net, #{DOMAIN}") }

      assert_equal 200, response.status
      assert_equal "https://#{DOMAIN}/login", response.body
    end

    def test_without_the_forwarded_host_the_function_url_host_is_blocked
      response = with_role('web') { request }

      assert_equal 403, response.status
    end

    def test_another_forwarded_host_is_blocked
      response = with_role('web') { request('HTTP_X_FORWARDED_HOST' => 'evil.example.net') }

      assert_equal 403, response.status
    end

    def test_the_function_url_host_is_not_accepted_as_forwarded_host
      response = with_role('web') { request('HTTP_X_FORWARDED_HOST' => FUNCTION_URL_HOST) }

      assert_equal 403, response.status
    end

    # Rails' standard behavior: Host must be allowed too.
    def test_nothing_changes_without_the_role
      response = with_role(nil) { request('HTTP_X_FORWARDED_HOST' => DOMAIN) }

      assert_equal 403, response.status
    end

    def test_the_middleware_comes_right_after_the_events_middleware
      classes = Rails.application.middleware.map(&:klass)

      assert_equal [RedmineServerlessBoot::EventsMiddleware, RedmineServerlessBoot::ForwardedHostMiddleware],
                   classes.first(2)
    end
  end
end
