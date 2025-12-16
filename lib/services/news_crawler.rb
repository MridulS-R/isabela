require 'open-uri'
require 'nokogiri'
require 'uri'

module Services
class NewsCrawler
  MIN_INTERVAL_PER_HOST = 1.0 # seconds

  def crawl_all
    NewsSource.where(active: true).find_each do |src|
      crawl_source_record(src)
    end
  end

  def crawl_source_record(src)
    community = src.community
    return unless community
    case src.kind.to_s
    when 'website'
      src.urls.each do |list_url|
        links = extract_links(list_url, src.link_selector)
        links.each { |url| ingest_article(url, src, community) }
      end
    when 'rss'
      # Placeholder: RSS flow could be added here if needed
    when 'sitemap'
      # Placeholder: parse sitemap XML and iterate URLs
    end
    src.update_columns(last_crawled_at: Time.current, last_error: nil)
  rescue => e
    src.update_columns(last_crawled_at: Time.current, last_error: "#{e.class}: #{e.message}") rescue nil
    Rails.logger.warn("crawl source error #{src.id}: #{e.class}: #{e.message}")
  end

  private
  def extract_links(list_url, selector)
    return [] unless allowed_by_robots?(list_url)
    html = throttled_fetch(list_url) rescue nil
    return [] unless html
    doc = Nokogiri::HTML(html)
    links = doc.css(selector.to_s).map { |a| a['href'] }.compact
    links.map { |href| absolutize(list_url, href) }.uniq
  end

  def ingest_article(url, src, community)
    normalized = url.to_s
    return unless allowed_by_robots?(normalized)
    html = throttled_fetch(normalized) rescue nil
    return unless html
    doc = Nokogiri::HTML(html)

    canonical = doc.at("link[rel='canonical']")&.[]('href')
    normalized = absolutize(url, canonical) if canonical.present?

    title = og(doc, 'og:title') || doc.at('title')&.text
    body_node = if src['body_selector']
      doc.css(src['body_selector'])
    else
      doc.css('article')
    end
    body = body_node.map(&:to_html).join("\n")
    published_at = meta_date(doc, src['date_selector']) || Time.current
    source = URI.parse(normalized).host rescue nil

    return if title.to_s.strip.empty? || body.to_s.strip.empty?

    art = Article.find_or_initialize_by(url: normalized)
    art.community = community
    art.title = title.to_s.strip
    art.body = body.to_s.strip
    art.published_at = published_at
    art.source = source
    art.save!
  rescue => e
    Rails.logger.warn("crawl error #{url}: #{e.class}: #{e.message}")
  end

  def og(doc, prop)
    doc.at("meta[property='#{prop}']")&.[]('content')
  end

  def meta_date(doc, selector)
    if selector.present?
      node = doc.at(selector)
      val = node&.[]('content') || node&.text
      return Time.parse(val) rescue nil
    end
    val = og(doc, 'article:published_time') || og(doc, 'og:updated_time')
    return Time.parse(val) rescue nil
  end

  def absolutize(base, href)
    return href if href.to_s =~ %r{^https?://}
    URI.join(base.to_s, href.to_s).to_s rescue href
  end

  # basic robots.txt check for User-agent: *
  def allowed_by_robots?(url)
    uri = URI.parse(url.to_s) rescue nil
    return true unless uri&.host
    robots_url = "#{uri.scheme}://#{uri.host}/robots.txt"
    rules = Rails.cache.fetch([:robots, uri.host], expires_in: 10.minutes) do
      begin
        txt = URI.open(robots_url, 'rb', &:read)
        parse_robots(txt)
      rescue
        { disallow: [] }
      end
    end
    path = uri.path.presence || '/'
    !rules[:disallow].any? { |rule| path.start_with?(rule) }
  end

  def parse_robots(text)
    disallow = []
    ua_all = false
    current_block_all = false
    text.to_s.each_line do |line|
      line = line.strip
      next if line.start_with?('#') || line.empty?
      if line =~ /^User-agent:\s*\*\s*$/i
        ua_all = true
        current_block_all = true
      elsif line =~ /^User-agent:/i
        current_block_all = false
      elsif current_block_all && line =~ /^Disallow:\s*(.*)$/i
        rule = Regexp.last_match(1).to_s.strip
        disallow << rule unless rule.empty?
      end
    end
    { disallow: disallow.uniq }
  end

  def throttled_fetch(url)
    uri = URI.parse(url.to_s) rescue nil
    host = uri&.host || 'default'
    key = [:crawl_next_at, host]
    now = Time.now
    next_at = Rails.cache.fetch(key) { now }
    if now < next_at
      sleep(next_at - now) if (next_at - now) < 2
    end
    body = URI.open(url, 'rb', &:read)
    Rails.cache.write(key, Time.now + MIN_INTERVAL_PER_HOST)
    body
  end
end
end
