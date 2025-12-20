module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
    def find_verified_user
      # Prefer signed session_token and UserSession linkage
      raw = cookies.signed[:session_token]
      if raw.present?
        digest = Digest::SHA256.hexdigest(raw)
        if (us = UserSession.includes(:user).find_by(token_digest: digest))
          return us.user
        end
      end
      # Fallback to nil (guest). Some channels may reject unless authenticated.
      nil
    end
  end
end

