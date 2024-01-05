# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.1.4"

# Asset pipeline and front end. No bundler/transpiler: the UI is server
# rendered with a handful of import-mapped modules.
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

gem "devise"
gem "twilio-ruby"

gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows]

  # Rails' own style guide. Run with `bundle exec rubocop`.
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rails-controller-testing"
  gem "shoulda-matchers"
  gem "simplecov", require: false

  # Blocks every outbound HTTP connection in the suite. Before this, creating
  # a user in a spec made a real request to api.twilio.com.
  gem "webmock"
end
