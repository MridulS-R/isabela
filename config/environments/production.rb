require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.assets.js_compressor = :uglifier if defined?(Uglifier)
  # Disable Sass CSS compression to avoid SassC parsing modern CSS syntax
  # emitted by Tailwind v4 (e.g., range media queries like `(width >= 40rem)`).
  # Sprockets will still serve the prebuilt CSS from app/assets/builds.
  config.assets.css_compressor = nil
  config.assets.compile = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info').to_sym
  # Use in-process async jobs by default; switch to a persistent adapter when needed
  config.active_job.queue_adapter = :async
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

  # Action Cable: allow any origin by default (Render routes through multiple hosts)
  # Tighten this with specific origins/domains once your deployment URL is fixed.
  config.action_cable.disable_request_forgery_protection = true
end
