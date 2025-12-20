class CommunityFollowsController < ApplicationController
  before_action :require_login

  def create
    community = Community.find_by!(slug: params[:slug])
    CommunityFollow.find_or_create_by!(user_id: current_user.id, community_id: community.id)
    redirect_back fallback_location: community_path(community.slug), notice: 'Following community.'
  end

  def destroy
    community = Community.find_by!(slug: params[:slug])
    CommunityFollow.where(user_id: current_user.id, community_id: community.id).delete_all
    redirect_back fallback_location: community_path(community.slug), notice: 'Unfollowed community.'
  end
end

