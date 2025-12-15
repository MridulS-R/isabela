require 'open-uri'
require 'nokogiri'
require 'uri'

class NewsCrawler
  def initialize(config_path: Rails.root.join('config/news_sources.yml'))
    @config = YAML.load_file(config_path)
  end

  def crawl_all
    Array(@config['sources']).each { |src| crawl_source(src) }
  end

  def crawl_source(src)
    community = Community.find_by(slug: src['community_slug'])
    return unless community
    list_urls = Array(src['list_urls'])
    list_urls.each do |list_url|
      links = extract_links(list_url, src['link_selector'])
      links.each do |url|
        ingest_article(url, src, community)
      end
    end
  end

  private
  def extract_links(list_url, selector)
    html = URI.open(list_url, 'rb', &:read) rescue nil
    return [] unless html
    doc = Nokogiri::HTML(html)
    links = doc.css(selector.to_s).map { |a| a['href'] }.compact
    links.map { |href| absolutize(list_url, href) }.uniq
  end

  def ingest_article(url, src, community)
    normalized = url.to_s
    html = URI.open(normalized, 'rb', &:read) rescue nil
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
end

