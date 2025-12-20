class ModerationScoreJob < ApplicationJob
  queue_as :default

  def perform(kind:, id:)
    case kind
    when 'post'
      post = Post.find_by(id: id)
      return unless post
      score_post(post)
    when 'comment'
      comment = Comment.find_by(id: id)
      return unless comment
      score_comment(comment)
    end
  end

  private
  def score_post(post)
    scorer = Services::ContentScorer.new(post.caption)
    tox = scorer.toxicity_score
    nsfw = scorer.nsfw_score
    needs = (tox >= 0.7 || nsfw >= 0.7)
    post.update_columns(toxicity_score: tox, nsfw_score: nsfw, needs_review: needs)
    if needs
      Report.create!(user: post.user, reportable: post, reason: 'auto:content_flag') rescue nil
    end
  end

  def score_comment(comment)
    scorer = Services::ContentScorer.new(comment.body)
    tox = scorer.toxicity_score
    comment.update_columns(toxicity_score: tox)
    if tox >= 0.7
      Report.create!(user: comment.user, reportable: comment, reason: 'auto:content_flag') rescue nil
    end
  end
end

