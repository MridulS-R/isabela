module Api
  module V1
    class SessionsController < ActionController::API
      def create
        user = User.find_by(email: params[:email].to_s.downcase)
        if user&.authenticate(params[:password])
          user.ensure_api_token!
          render json: { token: user.api_token, user: { id: user.id, email: user.email, name: user.name } }, status: :created
        else
          render json: { error: 'invalid credentials' }, status: :unauthorized
        end
      end
    end
  end
end

