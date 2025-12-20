class PromotionsController < ApplicationController
  def click
    rec = PromotedPost.find(params[:id])
    rec.increment_click! rescue nil
    redirect_to post_path(rec.post_id)
  end
end

