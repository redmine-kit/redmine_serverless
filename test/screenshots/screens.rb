# frozen_string_literal: true

require_relative 'screenshot_case'

# The screens of docs/admin.md, on a function as Lambda sets it up (the names
# and the image are examples).
class RedmineServerlessScreenshotsTest < ScreenshotCase
  LAMBDA = {
    'REDMINE_ROLE' => 'web',
    'AWS_LAMBDA_FUNCTION_NAME' => 'redmine-web',
    'AWS_LAMBDA_FUNCTION_VERSION' => '$LATEST',
    'AWS_LAMBDA_FUNCTION_MEMORY_SIZE' => '2048',
    'AWS_REGION' => 'ap-northeast-1',
    'REDMINE_IMAGE' => '111122223333.dkr.ecr.ap-northeast-1.amazonaws.com/redmine:sha256-0f1e2d3c'
  }.freeze

  def setup
    super
    @saved = LAMBDA.keys.index_with { |name| ENV.fetch(name, nil) }
    ENV.update(LAMBDA)
  end

  def teardown
    @saved.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end

  def test_screens
    each_language do |language|
      visit '/admin/serverless/status'
      shoot 'admin-menu', language, selector: '#sidebar ul'

      click_link I18n.t(:button_test, locale: language)
      assert_selector 'table.list.checks'
      shoot 'status', language

      visit '/settings?tab=repositories'
      assert_selector '.serverless-fixed'
      page.execute_script("document.getElementById('settings_autofetch_changesets').closest('.box').id = 'fixed-box'")
      hide_after '#fixed-box'
      shoot 'fixed-settings', language, selector: '#tab-content-repositories'
    end
  end
end
