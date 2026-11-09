# frozen_string_literal: true

# The shared entry of the Serverless administration menu (every Redmine
# Serverless plugin draws it; the first one matches).
get 'admin/serverless', to: 'serverless_admin#index'

get 'admin/serverless/status', to: 'serverless_status#index', as: 'serverless_status'
post 'admin/serverless/status/check', to: 'serverless_status#check', as: 'serverless_status_check'
