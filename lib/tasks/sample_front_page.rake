namespace :setup do
  desc 'Create a root admin user and a sample front page article (lead)'
  task root_and_front_page: :environment do
    # Create or update root user
    email = ENV['ROOT_EMAIL'].presence || 'root@communnity.example'
    password = ENV['ROOT_PASSWORD'].presence || 'Password123!'

    user = User.find_or_initialize_by(email: email)
    if user.new_record?
      user.name = 'Root'
      user.password = password
      user.confirmed_at = Time.current
      user.role = :admin if user.respond_to?(:role)
      user.save!
      puts "Created root user: #{email} (password: #{password})"
    else
      user.update!(confirmed_at: (user.confirmed_at || Time.current))
      puts "Found existing user: #{email}"
    end

    # Ensure a default community exists
    community = Community.find_or_create_by!(slug: 'general') do |c|
      c.name = 'General'
      c.description = 'Default community.'
      c.visibility = :publicly_visible
      c.created_by = user
    end
    puts "Using community: #{community.slug}"

    # Create or update a lead HomepageArticle
    sample_meta = {
      title: 'Local Makers Unite for #CommunNity Fair',
      subheading: 'From food stalls to robotics demos, a celebration of neighbors building together.'
    }

    sample_html = <<~HTML
      <img src="https://images.unsplash.com/photo-1521335629791-ce4aec67dd53?w=1600&q=80" alt="Community fair" />
      <p>Under clear skies and a friendly buzz, neighbors gathered for the first annual <strong>#CommunNity</strong> Fair — a hands‑on showcase of projects, local food, and music. Organizers said the event grew from a simple idea: give makers, clubs, and small businesses a welcoming place to share what they’re building.</p>
      <p>Highlights included a robotics demo from the school club, a repair station for bikes, and a rotating lineup of acoustic sets. Volunteers helped run a kid’s corner with craft kits and a mini‑library swap.</p>
      <img src="https://images.unsplash.com/photo-1519682337058-a94d519337bc?w=1200&q=80" alt="Robotics demo" />
      <h2>What’s Next</h2>
      <p>Organizers plan monthly meetups and a quarterly fair, inviting more neighborhoods to participate. Interested groups can sign up in the forum and propose demos or workshops for the next edition.</p>
    HTML

    record = HomepageArticle.where(community_id: community.id, slot: :lead).first_or_initialize
    record.status = :published
    record.position = 0
    record.published_at ||= Time.current
    record.metadata = sample_meta
    record.content_html = sample_html
    record.created_by ||= user
    record.save!
    puts "Front page article ready (slot: lead, community: #{community.slug})."

    puts "Tip: set ENV ADMIN_EMAIL=#{email} to access admin features with this user."
  end
end
