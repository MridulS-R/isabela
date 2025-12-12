class RefreshFeedJob < ApplicationJob
  queue_as :default

  def perform(feed_id)
    require 'open-uri'
    require 'rss'
    feed = Feed.find(feed_id)
    xml = URI.open(feed.url, 'rb', redirect: true, &:read)
    parsed = RSS::Parser.parse(xml, false)

    title = parsed.respond_to?(:title) ? parsed.title.to_s : nil
    items = if parsed.respond_to?(:items)
      parsed.items
    elsif parsed.respond_to?(:entries)
      parsed.entries
    else
      []
    end

    items.each do |entry|
      art_title = (entry.respond_to?(:title) ? entry.title.to_s : '').to_s.strip
      next if art_title.blank?
      link  = if entry.respond_to?(:link)
                entry.link.is_a?(String) ? entry.link : (entry.link.respond_to?(:href) ? entry.link.href : entry.link.to_s)
              else
                nil
              end
      published = if entry.respond_to?(:published)
                    entry.published
                  elsif entry.respond_to?(:pubDate)
                    entry.pubDate
                  else
                    nil
                  end
      content = if entry.respond_to?(:content)
                  entry.content.respond_to?(:content) ? entry.content.content.to_s : entry.content.to_s
                elsif entry.respond_to?(:summary)
                  entry.summary.to_s
                elsif entry.respond_to?(:description)
                  entry.description.to_s
                else
                  ''
                end

      art = link.present? ? Article.find_or_initialize_by(url: link) : Article.find_or_initialize_by(title: art_title)
      art.title = art_title
      art.body = content.presence || art_title
      art.published_at = published || art.published_at || Time.current
      art.source = title if art.respond_to?(:source)
      art.save!
    end

    feed.update!(title: title.presence || feed.title, last_fetched_at: Time.current, last_error: nil)
  rescue => e
    feed.update_columns(last_error: "#{e.class}: #{e.message}", last_fetched_at: Time.current) rescue nil
    raise
  end
end

