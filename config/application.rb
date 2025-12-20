require_relative 'boot'
require "rails"
require_relative "../lib/login_throttle"
require "active_record/railtie"
require "active_storage/engine"
require "active_job/railtie"
require "action_mailer/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"

Bundler.require(*Rails.groups) if defined?(Bundler)

module Visiondata
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = 'UTC'
    # Load lib/ for custom middleware and services (production eager loading)
    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')
    config.generators do |g|
      g.orm :active_record
      g.test_framework nil
      g.assets false
      g.helper false
    end

    # Lightweight login throttle (Rack::Attack alternative without gem)
    config.middleware.use ::LoginThrottle
  end
end
