class LoginThrottle
  WINDOW = 60 # seconds
  MAX_ATTEMPTS = 10

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.post? && req.path == '/login'
      key = "login:#{req.ip}:#{Time.now.to_i / WINDOW}"
      count = cache_fetch(key) || 0
      if count >= MAX_ATTEMPTS
        return [429, { 'Content-Type' => 'text/plain' }, ['Too many attempts. Try again shortly.']]
      else
        cache_write(key, count + 1)
      end
    end
    @app.call(env)
  end

  private
  def cache_fetch(key)
    Rails.cache.fetch(key, expires_in: WINDOW.seconds) { nil }
  end

  def cache_write(key, value)
    Rails.cache.write(key, value, expires_in: WINDOW.seconds)
  end
end

