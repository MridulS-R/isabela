source "https://rubygems.org"

ruby File.read('.ruby-version').strip rescue RUBY_VERSION

gem 'rails', '~> 7.1.4'
gem 'puma', '>= 5.0'
gem 'sassc-rails'
gem 'sprockets-rails'
gem 'bcrypt', '~> 3.1'
# RSS/Atom feed parsing for News imports
gem 'rss'

group :development do
  gem 'web-console'
end

group :development, :test do
  gem 'sqlite3', '~> 1.4'
end

group :production do
  gem 'pg', '>= 1.4'
end
