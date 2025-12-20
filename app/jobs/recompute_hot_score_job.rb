class RecomputeHotScoreJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    score = Services::HotRanker.score(post)
    post.update_columns(hot_score: score)
  end
end

