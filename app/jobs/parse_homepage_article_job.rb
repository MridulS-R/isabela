class ParseHomepageArticleJob < ApplicationJob
  queue_as :default

  def perform(id)
    rec = HomepageArticle.find(id)
    raise 'No md_file attached' unless rec.md_file.attached?
    parser = HomepageMdParser
    io = rec.md_file.download
    result = parser.parse(StringIO.new(io))

    # Validate required metadata
    data = result.metadata || {}
    rec.metadata = data
    rec.content_html = sanitize_html(result.html)
    rec.save!
  end

  private
  def sanitize_html(html)
    allowed_tags = %w[p br h1 h2 h3 strong em b i a img ul ol li blockquote]
    allowed_attributes = %w[href src alt title rel target]
    ActionController::Base.helpers.sanitize(html.to_s, tags: allowed_tags, attributes: allowed_attributes)
  end
end

