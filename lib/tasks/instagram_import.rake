namespace :instagram do
  desc "Import Instagram-like users from CSV.\n" \
       "Usage: rails \"instagram:import_users[/absolute/path/to/instagram.csv,import.local]\"\n" \
       "CSV headers supported (flexible): username, user, name, full_name, email, bio, followers, avatar_url.\n" \
       "Followers: comma/semicolon-separated list; creates user records for them as well (no follow graph)."
  task :import_users, [:csv_path, :email_domain] => :environment do |_, args|
    require 'csv'
    require 'open-uri'
    require 'securerandom'

    csv_path = File.expand_path(args[:csv_path].to_s)
    abort "Provide csv_path: rails 'instagram:import_users[/path/to/instagram.csv]'" if csv_path.empty?
    abort "CSV not found: #{csv_path}" unless File.exist?(csv_path)

    domain = (args[:email_domain].presence || 'import.local').to_s

    def slugify(str)
      str.to_s.downcase.strip.gsub(/[^a-z0-9_]+/, '_').gsub(/^_+|_+$/, '')
    end

    def ensure_unique_username(base)
      u = base
      i = 1
      while u.present? && User.exists?(username: u)
        i += 1
        u = "#{base}_#{i}"
      end
      u
    end

    def ensure_unique_email(base_email)
      if !User.exists?(email: base_email)
        return base_email
      end
      local, dom = base_email.split('@', 2)
      i = 1
      loop do
        candidate = "#{local}+#{i}@#{dom}"
        return candidate unless User.exists?(email: candidate)
        i += 1
      end
    end

    created = 0
    updated = 0
    follower_created = 0

    CSV.foreach(csv_path, headers: true) do |row|
      h = row.to_h
      username = h['username'] || h['user']
      full_name = h['full_name'] || h['name']
      email = h['email']
      bio = h['bio']
      avatar_url = h['avatar_url']
      followers = h['followers']

      uname = slugify(username.presence || full_name.presence || SecureRandom.hex(4))
      uname = ensure_unique_username(uname) if uname.present?

      if email.present?
        email = email.strip.downcase
      else
        base_email = "#{uname.presence || SecureRandom.hex(6)}@#{domain}"
        email = ensure_unique_email(base_email)
      end

      user = User.find_by(email: email) || (uname.present? ? User.find_by(username: uname) : nil)
      if user
        changes = {}
        changes[:name] = full_name if full_name.present? && user.name.to_s.strip.empty?
        if uname.present? && user.username.blank?
          final_uname = ensure_unique_username(uname)
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

      # Followers as new users (no relationships stored; creates users only)
      if followers.present?
        list = followers.split(/[,;\n]+/).map(&:strip).reject(&:blank?)
        list.each do |f|
          f_uname = slugify(f)
          next if f_uname.blank?
          f_email = ensure_unique_email("#{f_uname}@#{domain}")
          next if User.exists?(username: f_uname) || User.exists?(email: f_email)
          begin
            User.create!(username: f_uname, email: f_email, password: SecureRandom.base58(12), name: f)
            follower_created += 1
          rescue ActiveRecord::RecordInvalid
            # skip invalid follower rows quietly
          end
        end
      end
    end

    puts "Users created: #{created}, updated: #{updated}, followers created: #{follower_created}"
  end
end

