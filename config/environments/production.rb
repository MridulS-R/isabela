require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.assets.js_compressor = :uglifier if defined?(Uglifier)
  config.assets.compile = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Allow Render hosts
  config.hosts << /.*\.onrender\.com/
  config.hosts << ENV['RENDER_EXTERNAL_HOSTNAME'] if ENV['RENDER_EXTERNAL_HOSTNAME']
end
