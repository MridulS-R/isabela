class ImportNewsRssJob < ApplicationJob
  queue_as :default

  # Args: url (preferred) OR blob_id/file_path for uploaded feed file
  def perform(url: nil, blob_id: nil, file_path: nil, source: nil)
    require 'open-uri'
    require 'rss'

    raise ArgumentError, 'Provide url, blob_id or file_path' if url.to_s.strip.empty? && blob_id.to_s.strip.empty? && file_path.to_s.strip.empty?

    xml = nil
    if blob_id.present?
      blob = ActiveStorage::Blob.find_signed(blob_id)
      xml = blob.download.force_encoding('UTF-8')
    elsif file_path.present?
      xml = File.read(file_path)
    else
      xml = URI.open(url, 'rb', redirect: true, &:read)
    end

    feed = RSS::Parser.parse(xml, false)
    feed_title = source.presence || (feed.respond_to?(:title) ? feed.title.to_s : nil)

    items = if feed.respond_to?(:items)
      feed.items
    elsif feed.respond_to?(:entries)
      feed.entries
    else
      []
    end

    items.each do |entry|
      title = (entry.respond_to?(:title) ? entry.title.to_s : nil).to_s.strip
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

      next if title.blank?

      art = if link.present?
        Article.find_or_initialize_by(url: link)
      else
        Article.find_or_initialize_by(title: title)
      end
      art.title = title
      art.body = content.presence || title
      art.published_at = published || art.published_at || Time.current
      art.source = feed_title if art.respond_to?(:source)
      art.save!
    end
  end
end

