class ImportRedditJob < ApplicationJob
  queue_as :default

  # Args:
  #   - url: http/https URL to CSV/JSON (optional)
  #   - file_path: absolute path to a CSV/JSON on disk (optional)
  #   - blob_id: ActiveStorage::Blob.signed_id of an uploaded CSV/JSON (preferred for uploads)
  #   - owner_email: optional email to own imported posts
  #   - community_id: required community for posts
  def perform(url: nil, file_path: nil, blob_id: nil, owner_email: nil, community_id: nil)
    require 'open-uri'
    require 'csv'
    require 'json'
    require 'base64'
    require 'stringio'
    require 'securerandom'
    require 'time'

    raise ArgumentError, 'one of url, file_path, or blob_id is required' if url.to_s.strip.empty? && file_path.to_s.strip.empty? && blob_id.to_s.strip.empty?

    owner = User.find_or_create_by!(email: (owner_email.presence || 'reddit-import@example.com')) do |u|
      u.name = 'Reddit Importer'
      u.password = SecureRandom.hex(12)
    end
    community = Community.find_by(id: community_id)

    body = nil
    ext = '.csv'
    if blob_id.present?
      blob = ActiveStorage::Blob.find_signed(blob_id)
      body = blob.download
      ext = File.extname(blob.filename.to_s).downcase unless File.extname(blob.filename.to_s).to_s.empty?
    elsif file_path.present?
      body = File.binread(file_path)
      ext = File.extname(file_path).downcase unless File.extname(file_path).to_s.empty?
    else
      io = URI.open(url, 'rb')
      body = io.read
      ext = File.extname(URI.parse(url).path).downcase unless File.extname(URI.parse(url).path).to_s.empty?
    end

    # 1x1 black PNG placeholder (base64)
    png_base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=='

    imported = 0

    parser = lambda do |hash|
      title = hash['title'] || hash['Title'] || hash['post_title'] || hash['Post Title'] || hash['name']
      subreddit = hash['subreddit'] || hash['Subreddit'] || hash['category']
      score = (hash['score'] || hash['ups'] || hash['Score'] || 0).to_i
      created = hash['created_utc'] || hash['created'] || hash['created_at']

      caption = title.to_s.strip
      return unless caption.present?

      post = Post.new(user: owner, caption: caption, likes_count: score, community: community)
      post.images.attach(io: StringIO.new(Base64.decode64(png_base64)), filename: 'placeholder.png', content_type: 'image/png')

      if post.save
        if subreddit.present?
          normalized = subreddit.to_s.downcase.gsub(/[^a-z0-9_]/, '_')
          tag = Tag.find_or_create_by!(name: normalized)
          post.tags << tag unless post.tags.exists?(id: tag.id)
        end

        if created.present?
          ts = begin
            Time.at(created.to_i)
          rescue
            begin Time.parse(created.to_s) rescue nil end
          end
          post.update_columns(created_at: ts, updated_at: ts) if ts
        end

        imported += 1
      end
    end

    if ext == '.json'
      JSON.parse(body).each { |row| parser.call(row) }
    else
      CSV.parse(body, headers: true).each { |row| parser.call(row.to_h) }
    end

    Rails.logger.info("Imported #{imported} Reddit posts for #{owner.email}")
  end
end
