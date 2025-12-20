module Services
class HotRanker
  # Simple hot score: likes + 0.5*comments - age_hours*decay
  def self.score(post)
    likes = post.likes_count.to_i
    comments = post.respond_to?(:comments_count) ? post.comments_count.to_i : post.comments.size
    age_hours = [(Time.current - post.created_at) / 3600.0, 0.0].max
    (likes + comments * 0.5) - (age_hours * 0.1)
  end
end
end

