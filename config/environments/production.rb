require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.assets.js_compressor = :uglifier if defined?(Uglifier)
  config.assets.compile = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info').to_sym
  # Set Active Storage service; default to :local. If an unsupported
  # adapter (e.g., "database") is provided via env, fall back to :local
  # to avoid boot errors in environments without that adapter.
  allowed_services = %w[local amazon azure gcs mirror]
  chosen = (ENV['ACTIVE_STORAGE_SERVICE'] || 'local').to_s.downcase
  chosen = 'local' unless allowed_services.include?(chosen)
  config.active_storage.service = chosen.to_sym

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = ::Logger::Formatter.new
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Allow Render hosts
  config.hosts << /.*\.onrender\.com/
  config.hosts << ENV['RENDER_EXTERNAL_HOSTNAME'] if ENV['RENDER_EXTERNAL_HOSTNAME']
end
