module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api!

      attr_reader :current_user

      private
      def authenticate_api!
        token = request.headers['X-Api-Token'].presence
        unless token
          authenticate_with_http_token do |t, _opts|
            token = t
          end
        end
        token ||= params[:api_token].presence
        if token.present?
          @current_user = User.find_by(api_token: token)
        end
        render json: { error: 'unauthorized' }, status: :unauthorized unless @current_user
      end
    end
  end
end

