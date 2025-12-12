class TagsController < ApplicationController
  def show
    @tag = Tag.find_by!(name: params[:name].downcase)
    @posts = @tag.posts.includes(:user, images_attachments: :blob).recent.limit(50)
  end
end

