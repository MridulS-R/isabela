module Services
class RateLimiter
  def self.allow?(key, limit:, period:)
    cache_key = ["rate", key]
    data = Rails.cache.read(cache_key) || { count: 0, reset_at: Time.now.to_i + period }
    now = Time.now.to_i
    if now > data[:reset_at]
      data = { count: 0, reset_at: now + period }
    end
    if data[:count] >= limit
      Rails.cache.write(cache_key, data, expires_in: period)
      return false
    end
    data[:count] += 1
    Rails.cache.write(cache_key, data, expires_in: period)
    true
  end
end
end

