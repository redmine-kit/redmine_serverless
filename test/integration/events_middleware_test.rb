# frozen_string_literal: true

require_relative '../test_helper'

module RedmineServerless
  class EventsMiddlewareTest < Redmine::IntegrationTest
    include RedmineServerless::TestHelper

    def test_events_returns_204_without_touching_the_database
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }
      with_role('web') do
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          post '/events', params: '{"source":"aws.events"}', headers: { 'CONTENT_TYPE' => 'application/json' }
        end
      end

      assert_response 204
      assert_empty response.body
      assert_empty queries
      assert_nil response.headers['Set-Cookie']
    end

    def test_other_paths_pass_through
      with_role('web') do
        get '/login'
      end

      assert_response :success
    end

    def test_events_is_not_handled_without_the_role
      with_role(nil) do
        post '/events'
      end

      assert_response :not_found
    end

    def test_the_middleware_is_first
      assert_equal RedmineServerlessBoot::EventsMiddleware, Rails.application.middleware.first.klass
    end
  end
end
