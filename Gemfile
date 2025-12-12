source "https://rubygems.org"

ruby File.read('.ruby-version').strip rescue RUBY_VERSION

gem 'rails', '~> 7.1'
gem 'puma', '>= 5.0'
gem 'sassc-rails'
gem 'sprockets-rails'

group :development do
  gem 'web-console'
end

group :development, :test do
  gem 'sqlite3', '~> 1.4'
end

