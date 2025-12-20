class TagsController < ApplicationController
  def show
    @tag = Tag.find_by!(name: params[:name].downcase)
    @posts = @tag.posts.where(hidden: false).includes(:user, images_attachments: :blob).recent.limit(50)
  end

  def community
    @community = Community.find_by!(slug: params[:slug])
    @tag = Tag.find_by!(name: params[:name].downcase)
    @posts = @tag.posts.where(community_id: @community.id, hidden: false)
                 .includes(:user, images_attachments: :blob)
                 .recent.limit(50)
  end
end
