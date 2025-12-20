class FollowsController < ApplicationController
  before_action :require_login

  def create
    user = User.find(params[:id])
    if user.id == current_user.id
      return redirect_back fallback_location: root_path, alert: 'You cannot follow yourself.'
    end
    current_user.active_follows.find_or_create_by!(followed: user)
    redirect_back fallback_location: root_path, notice: 'Followed.'
  end

  def destroy
    user = User.find(params[:id])
    current_user.active_follows.where(followed_id: user.id).delete_all
    redirect_back fallback_location: root_path, notice: 'Unfollowed.'
  end
end

