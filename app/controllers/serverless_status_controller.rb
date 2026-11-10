# frozen_string_literal: true

# The "Status" tab (docs/admin.md#status-and-connections).
class ServerlessStatusController < ApplicationController
  layout 'admin'
  self.main_menu = false
  menu_item :serverless

  before_action :require_admin

  def index
    @status = RedmineServerless::Status.new
  end

  def check
    @status = RedmineServerless::Status.new
    @results = RedmineServerlessAdmin.run_checks
    failed = @results.reject(&:ok).map(&:name)
    failed = failed.join(', ').presence || 'none'
    logger&.info "[redmine_serverless] #{User.current.login} ran the connection check; failed: #{failed}"
    render :index
  end
end
