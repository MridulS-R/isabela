module Api
  module V1
    class PostsController < Api::V1::BaseController
      def create
        post = @current_user.posts.build(caption: params[:caption])
        if params[:community_id].present?
          post.community_id = params[:community_id]
        end
        if post.save
          render json: { post_id: post.id }, status: :created
        else
          render json: { error: post.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end
      end

      def like
        post = Post.find(params[:id])
        @current_user.likes.find_or_create_by!(post: post)
        render json: { ok: true }
      end

      def unlike
        @current_user.likes.where(post_id: params[:id]).delete_all
        render json: { ok: true }
      end

      def comment
        post = Post.find(params[:id])
        post.comments.create!(user: @current_user, body: params[:body].to_s)
        render json: { ok: true }
      end
    end
  end
end

