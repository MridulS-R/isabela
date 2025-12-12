class ImportInstagramUsersJob < ApplicationJob
  queue_as :default

  # Args:
  #   - url: http/https URL to CSV/JSON (optional)
  #   - file_path: absolute path on disk (optional)
  #   - blob_id: ActiveStorage::Blob.signed_id for uploaded file (preferred for UI uploads)
  #   - email_domain: fallback domain for generated emails (default: import.local)
  def perform(url: nil, file_path: nil, blob_id: nil, email_domain: 'import.local')
    require 'open-uri'
    require 'csv'
    require 'json'
    require 'securerandom'

    raise ArgumentError, 'one of url, file_path, or blob_id is required' if url.to_s.strip.empty? && file_path.to_s.strip.empty? && blob_id.to_s.strip.empty?

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

    created = 0
    updated = 0
    follower_created = 0
    follows_created = 0

    slugify = ->(str) { str.to_s.downcase.strip.gsub(/[^a-z0-9_]+/, '_').gsub(/^_+|_+$/, '') }

    ensure_unique_username = lambda do |base|
      u = base
      i = 1
      while u.present? && User.exists?(username: u)
        i += 1
        u = "#{base}_#{i}"
      end
      u
    end

    ensure_unique_email = lambda do |base_email|
      return base_email unless User.exists?(email: base_email)
      local, dom = base_email.split('@', 2)
      i = 1
      loop do
        candidate = "#{local}+#{i}@#{dom}"
        return candidate unless User.exists?(email: candidate)
        i += 1
      end
    end

    parse_row = lambda do |h|
      username = h['username'] || h['user']
      full_name = h['full_name'] || h['name']
      email = h['email']
      bio = h['bio']
      avatar_url = h['avatar_url']
      followers = h['followers']

      uname = slugify.call(username.presence || full_name.presence || SecureRandom.hex(4))
      uname = ensure_unique_username.call(uname) if uname.present?

      if email.present?
        email = email.strip.downcase
      else
        base_email = "#{uname.presence || SecureRandom.hex(6)}@#{email_domain}"
        email = ensure_unique_email.call(base_email)
      end

      user = User.find_by(email: email) || (uname.present? ? User.find_by(username: uname) : nil)
      if user
        changes = {}
        changes[:name] = full_name if full_name.present? && user.name.to_s.strip.empty?
        if uname.present? && user.username.blank?
          final_uname = ensure_unique_username.call(uname)
          changes[:username] = final_uname
        end
        changes[:bio] = bio if bio.present? && user.bio.to_s.strip.empty?
        if changes.any?
          user.update!(changes)
          updated += 1
        end
      else
        password = SecureRandom.base58(12)
        attrs = { email: email, password: password }
        attrs[:name] = full_name if full_name.present?
        attrs[:username] = uname if uname.present?
        attrs[:bio] = bio if bio.present?
        user = User.create!(attrs)
        created += 1
      end

      if avatar_url.present?
        begin
          file_io = URI.open(avatar_url)
          filename = File.basename(URI.parse(avatar_url).path.presence || 'avatar.jpg')
          user.avatar.attach(io: file_io, filename: filename)
        rescue => e
          Rails.logger.warn("Avatar fetch failed for #{avatar_url}: #{e.class}: #{e.message}")
        end
      end

      if followers.present?
        list = followers.split(/[,;\n]+/).map(&:strip).reject(&:blank?)
        list.each do |f|
          f_uname = slugify.call(f)
          next if f_uname.blank?
          candidate_email = "#{f_uname}@#{email_domain}"
          f_email = ensure_unique_email.call(candidate_email)
          follower_user = User.find_by(username: f_uname) || User.find_by(email: candidate_email)
          unless follower_user
            begin
              follower_user = User.create!(username: f_uname, email: f_email, password: SecureRandom.base58(12), name: f)
              follower_created += 1
            rescue ActiveRecord::RecordInvalid
              next
            end
          end
          # Create follow edge: follower_user -> user
          if follower_user && follower_user.id != user.id
            begin
              Follow.create!(follower: follower_user, followed: user)
              follows_created += 1
            rescue ActiveRecord::RecordInvalid
            end
          end
        end
      end
    end

    if ext == '.json'
      JSON.parse(body).each { |row| parse_row.call(row) }
    else
      CSV.parse(body, headers: true).each { |row| parse_row.call(row.to_h) }
    end

    Rails.logger.info("Instagram import users created: #{created}, updated: #{updated}, follower users created: #{follower_created}, follows created: #{follows_created}")
  end
end
