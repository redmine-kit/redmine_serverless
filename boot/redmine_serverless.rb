# frozen_string_literal: true

# The part of Redmine Serverless that must be in place before Rails finishes
# initializing: the /events middleware and the asset setting. Bundler loads
# this file (the plugin is also a gem); init.rb, which Redmine runs later,
# does the rest. It is outside lib/, which Redmine autoloads.
module RedmineServerlessBoot
  # Answers Lambda Web Adapter's /events with 204 before anything else runs,
  # so that it never touches the database or a session. Other paths, and
  # every path when REDMINE_ROLE is not set, pass through.
  class EventsMiddleware
    PATH = '/events'

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless ENV.fetch('REDMINE_ROLE', '') != '' && env['PATH_INFO'] == PATH

      [204, {}, []]
    end
  end

  if defined?(Rails::Railtie)
    class Railtie < Rails::Railtie
      config.app_middleware.insert_before 0, EventsMiddleware

      # Redmine checks after initialization whether the assets changed and
      # writes them to public/assets; on Lambda the image has them compiled
      # and the file system is read-only. This runs before Redmine's check,
      # which is registered later.
      config.after_initialize do |app|
        app.config.assets.redmine_detect_update = false if ENV.fetch('REDMINE_ROLE', '') != ''
      end
    end
  end
end
