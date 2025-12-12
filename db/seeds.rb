Article.find_or_create_by!(title: 'Guide: Building High‑Quality B2B Audiences') do |p|
  p.body = <<~BODY
    Translate your ICP into concrete filters and signals. Start with industry, company size, and geography, then add technographics and intent. Validate early with small campaigns and iterate on match/response rates.
  BODY
  p.published_at = Time.now
end

Article.find_or_create_by!(title: 'Case Study: 27% Lower CPL with Enrichment') do |p|
  p.body = <<~BODY
    See how enrichment improved routing and conversion for a SaaS team by filling contact gaps, normalizing company names, and scoring leads for SDR prioritization.
  BODY
  p.published_at = Time.now - 7.days
end

# Optional: seed or update an admin user via env vars
if ENV['ADMIN_EMAIL'].present?
  admin_email = ENV['ADMIN_EMAIL']
  admin_password = ENV['ADMIN_PASSWORD']
  user = User.find_or_initialize_by(email: admin_email)
  user.name = (user.name.presence || 'Admin')
  if user.new_record?
    if admin_password.blank?
      puts "ADMIN_PASSWORD not set; skipping admin creation"
    else
      user.password = admin_password
      user.save!
      puts "Created admin user #{admin_email}"
    end
  else
    if admin_password.present?
      user.password = admin_password
      user.save!
      puts "Updated admin user password for #{admin_email}"
    else
      puts "Admin user #{admin_email} exists; no password change"
    end
  end
end
