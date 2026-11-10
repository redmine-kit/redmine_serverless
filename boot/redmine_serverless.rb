# frozen_string_literal: true

# The part of Redmine Serverless that must be in place before Rails finishes
# initializing: the /events and forwarded host middlewares and the asset
# setting. Bundler loads this file (the plugin is also a gem); init.rb, which
# Redmine runs later, does the rest. It is outside lib/, which Redmine
# autoloads.
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

  # Makes the Redmine domain the Host of requests on Lambda. They come through
  # CloudFront and the function URL, whose own host name is the Host (the
  # function URL and origin access control need it), and CloudFront passes the
  # domain in X-Forwarded-Host, an origin custom header that replaces one sent
  # by the viewer. Rails' host authorization checks both Host and
  # X-Forwarded-Host against config.hosts, which holds only the domain; with the
  # domain in Host, Rails checks and builds URLs with the domain alone. Without
  # X-Forwarded-Host the function URL's host stays and the request is blocked.
  # Every request passes unchanged when REDMINE_ROLE is not set.
  class ForwardedHostMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if ENV.fetch('REDMINE_ROLE', '') != ''
        host = env['HTTP_X_FORWARDED_HOST'].to_s.split(/,\s?/).last
        env['HTTP_HOST'] = host if host.present?
      end
      @app.call(env)
    end
  end

  if defined?(Rails::Railtie)
    class Railtie < Rails::Railtie
      config.app_middleware.insert_before 0, EventsMiddleware
      # Before Rails' host authorization, which is the first middleware of the
      # stack when config.hosts is not empty.
      config.app_middleware.insert_after EventsMiddleware, ForwardedHostMiddleware

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
