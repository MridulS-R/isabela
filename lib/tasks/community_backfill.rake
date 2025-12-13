namespace :community do
  desc "Backfill communities/topics: create a default community, assign posts/articles, and derive topics from #community_topic"
  task backfill: :environment do
    default_owner = User.first || User.create!(email: 'owner@example.com', password: 'Password123', name: 'Owner')
    general = Community.find_or_create_by!(slug: 'general') do |c|
      c.name = 'General'
      c.created_by = default_owner
      c.visibility = :public
    end

    puts "Default community: #{general.slug}"

    Post.where(community_id: nil).find_each do |p|
      # Try to infer from caption like #dev_topic
      match = p.caption.to_s.downcase.match(/#([a-z0-9]+)_([a-z0-9_]+)/)
      community = nil
      if match
        cslug = match[1]
        community = Community.find_or_create_by!(slug: cslug) do |c|
          c.name = cslug.humanize
          c.created_by = default_owner
          c.visibility = :public
        end
      end
      p.update_columns(community_id: (community || general).id)
    end

    Article.where(community_id: nil).update_all(community_id: general.id)

    # Recompute topics from captions
    Post.find_each do |p|
      next unless p.community_id
      pairs = p.caption.to_s.downcase.scan(/#([a-z0-9]+)_([a-z0-9_]+)/).uniq
      topics = []
      pairs.each do |(cslug, tslug)|
        next unless cslug == p.community.slug
        topics << Topic.find_or_create_by!(community_id: p.community_id, slug: tslug) { |t| t.name = tslug.humanize }
      end
      p.topics = topics if topics.any?
    end

    puts 'Backfill complete.'
  end
end

