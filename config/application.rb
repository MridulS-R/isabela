require_relative 'boot'
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"

Bundler.require(*Rails.groups) if defined?(Bundler)

module Visiondata
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = 'UTC'
    config.generators do |g|
      g.orm :active_record
      g.test_framework nil
      g.assets false
      g.helper false
    end
  end
end
