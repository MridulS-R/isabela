class UsersPublicController < ApplicationController
  def show
    @user = User.find(params[:id])
    tab = params[:tab].to_s
    posts = Post.where(user_id: @user.id).includes(images_attachments: :blob)
    if tab == 'media'
      posts = posts.joins(:images_attachments)
    end
    @posts = posts.order(created_at: :desc).limit(50)
  end
end

