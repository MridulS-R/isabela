class AutoTagPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    text = [post.caption].compact.join(' ')
    tags = Services::AiTagger.new.suggest_tags(text, limit: 5)
    tags.each do |name|
      next if name.length < 3
      tag = Tag.find_or_create_by!(name: name)
      Tagging.find_or_create_by!(post_id: post.id, tag_id: tag.id)
    end
  rescue => e
    Rails.logger.warn("AutoTagPostJob error for post=#{post_id}: #{e.class}: #{e.message}")
  end
end

