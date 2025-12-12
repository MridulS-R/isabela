namespace :kaggle do
  desc "Import Reddit posts CSV (Kaggle output).\n" \
       "Usage: rails 'kaggle:import_reddit[/absolute/path/to/file.csv,owner@example.com]'\n" \
       "If owner email is omitted, a default importer user is created."
  task :import_reddit, [:csv_path, :owner_email] => :environment do |_, args|
    require 'csv'
    require 'securerandom'
    require 'base64'
    require 'stringio'
    require 'time'

    csv_path = args[:csv_path].to_s
    abort "Provide csv_path or URL: rails 'kaggle:import_reddit[/path/to/file.csv]'" if csv_path.empty?

    # Support http(s) URL by downloading to a Tempfile
    if csv_path =~ %r{^https?://}
      require 'open-uri'
      tmp = Tempfile.new(['reddit', File.extname(URI.parse(csv_path).path)])
      URI.open(csv_path, "rb") { |io| IO.copy_stream(io, tmp) }
      tmp.flush
      csv_path = tmp.path
      at_exit { tmp.close! rescue nil }
    end

    abort "CSV not found: #{csv_path}" unless File.exist?(csv_path)

    owner_email = args[:owner_email].presence || 'reddit-import@example.com'
    owner = User.find_or_create_by!(email: owner_email) do |u|
      u.name = 'Reddit Importer'
      u.password = SecureRandom.hex(12)
    end

    # 1x1 black PNG (base64)
    png_base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=='

    imported = 0
    parser = lambda do |hash|
      title = hash['title'] || hash['Title'] || hash['post_title'] || hash['Post Title'] || hash['name']
      subreddit = hash['subreddit'] || hash['Subreddit'] || hash['category']
      score = (hash['score'] || hash['ups'] || hash['Score'] || 0).to_i
      created = hash['created_utc'] || hash['created'] || hash['created_at']

      caption = title.to_s.strip
      return unless caption.present?

      post = owner.posts.build(caption: caption, likes_count: score)
      post.images.attach(io: StringIO.new(Base64.decode64(png_base64)),
                         filename: 'placeholder.png',
                         content_type: 'image/png')

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

    if File.extname(csv_path).downcase == '.json'
      require 'json'
      data = JSON.parse(File.read(csv_path))
      data.each do |row|
        parser.call(row)
      end
    else
      CSV.foreach(csv_path, headers: true) do |row|
        parser.call(row.to_h)
      end
    end

    puts "Imported #{imported} posts into user #{owner.email}"
  end
end
