# frozen_string_literal: true

require_relative '../test_helper'

class ServerlessAdminControllerTest < Redmine::ControllerTest
  def test_index_opens_the_first_tab
    @request.session[:user_id] = 1
    get :index

    assert_redirected_to '/admin/serverless/status'
  end

  def test_non_administrators_are_refused
    @request.session[:user_id] = 2
    get :index

    assert_response :forbidden
  end

  def test_one_menu_item
    items = Redmine::MenuManager.items(:admin_menu).children.select { |item| item.name == :serverless }

    assert_equal 1, items.size
  end
end
