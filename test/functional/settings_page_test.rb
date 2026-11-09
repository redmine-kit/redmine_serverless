# frozen_string_literal: true

require_relative '../test_helper'

module RedmineServerless
  class SettingsPageTest < Redmine::ControllerTest
    include RedmineServerless::TestHelper

    tests SettingsController

    def setup
      @request.session[:user_id] = 1
    end

    def test_the_fixed_settings_are_disabled_on_lambda
      with_role('web') do
        get :edit, params: { tab: 'repositories' }
      end

      assert_response :success
      assert_includes response.body, 'settings[sys_api_enabled]'
      assert_includes response.body, 'Not available in a serverless environment'
    end

    def test_standard_page_without_the_role
      with_role(nil) do
        get :edit
      end

      assert_response :success
      assert_not_includes response.body, 'Not available in a serverless environment'
    end
  end
end
