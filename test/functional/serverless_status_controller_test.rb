# frozen_string_literal: true

require_relative '../test_helper'

class ServerlessStatusControllerTest < Redmine::ControllerTest
  include RedmineServerless::TestHelper

  def setup
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    with_role('web') do
      get :index
    end

    assert_response :success
    assert_select 'h2', text: 'Serverless'
    assert_select 'div.tabs a#tab-status.selected'
    assert_select 'div.box.tabular p', text: /Role\s*web\s*REDMINE_ROLE/
    assert_select 'div.box.tabular p label', text: /Redmine Serverless/
    assert_select 'div.box.tabular p em.info', text: 'sys_api_enabled'
    assert_select 'table.list', 0, 'name/value data is laid out as .box.tabular rows, not tables'
    assert_select 'h3', text: 'Read-only settings'
    assert_select 'div.box.tabular p', text: /Enable WS for repository management\s*No\s*sys_api_enabled/
    assert_select 'div.box.tabular p em.info', text: 'enabled_scm', count: 0
    assert_select 'p a[data-method=post]:not(.icon)', text: 'Test'
  end

  def test_index_without_the_role
    with_role(nil) do
      get :index
    end

    assert_response :success
    assert_select 'p.nodata', text: 'No data to display'
  end

  def test_check_runs_the_connection_checks
    post :check

    assert_response :success
    assert_select 'table.list.checks tr.ok td.name', text: 'Database'
    assert_select 'table.list.checks tr.ok td.description', text: /\APostgreSQL \d+(\.\d+)*\z/
    assert_select 'table.list.checks th', text: 'Response time (ms)'
    assert_select 'table.list.checks tr.ok td.milliseconds', text: /\A[\d,]+\z/
    assert_select 'table.list.checks tr.ok td.tick span.icon-ok'
  end

  def test_a_failing_check_is_shown_and_the_page_still_opens
    RedmineServerlessAdmin.register_check(:broken, label: :label_serverless_failed) { raise IOError, 'unreachable' }
    post :check

    assert_response :success
    assert_select 'table.list.checks tr.failed td.description', text: 'IOError: unreachable'
    assert_select 'table.list.checks tr.failed td.tick span.icon-error'
  ensure
    RedmineServerlessAdmin.instance_variable_get(:@checks).delete('broken')
  end

  def test_no_secret_values_on_the_page
    ENV['SECRET_KEY_BASE_FOR_TEST'] = 'not-shown-secret-value'
    get :index
    post :check

    assert_not_includes response.body, 'not-shown-secret-value'
    assert_not_includes response.body, Rails.application.secret_key_base
  ensure
    ENV.delete('SECRET_KEY_BASE_FOR_TEST')
  end

  def test_non_administrators_are_refused
    @request.session[:user_id] = 2
    get :index

    assert_response :forbidden
    post :check

    assert_response :forbidden
  end
end
