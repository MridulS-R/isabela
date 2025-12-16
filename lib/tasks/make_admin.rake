namespace :setup do
  desc 'Confirm a user and make them admin. Usage: rake setup:make_admin EMAIL=you@example.com [PASSWORD=Pass123!]'
  task make_admin: :environment do
    email = (ENV['EMAIL'] || ENV['TARGET_EMAIL'] || ENV['ADMIN_EMAIL']).to_s.strip.downcase
    if email.blank?
      abort "Provide EMAIL=you@example.com"
    end

    user = User.find_or_initialize_by(email: email)
    created = user.new_record?
    if created
      password = (ENV['PASSWORD'].presence || 'Password123!')
      user.name ||= email.split('@').first
      user.password = password
    end
    user.confirmed_at ||= Time.current
    user.role = :admin if user.respond_to?(:role)
    user.save!

    puts created ? "Created user: #{email}" : "Updated user: #{email}"
    puts "- Confirmed: yes"
    puts "- Role: #{user.role}"
    puts "- Password: #{password}" if created
    unless ENV['ADMIN_EMAIL'].to_s.downcase == email
      puts "Tip: set ENV ADMIN_EMAIL=#{email} to enable email-based admin access."
    end
  end
end

