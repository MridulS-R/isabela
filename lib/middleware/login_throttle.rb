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
      count = Rails.cache.fetch(key, expires_in: WINDOW.seconds) { 0 }
      if count >= MAX_ATTEMPTS
        return [429, { 'Content-Type' => 'text/plain' }, ['Too many attempts. Try again shortly.']]
      else
        Rails.cache.write(key, count + 1, expires_in: WINDOW.seconds)
      end
    end
    @app.call(env)
  end
end

