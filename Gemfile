# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.2.2"

gem "rails", "~> 7.1.1"

# Asset pipeline and front end. No bundler/transpiler: the UI is server
# rendered with a handful of import-mapped modules.
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Rails 7.1 is not compatible with the json 3.x series: both
# ActiveSupport::JSON::Encoding and rack-session 2.0 call
# JSON.generate(..., quirks_mode: true), a keyword json 3 removed. Nothing
# in the app requires json directly, but RuboCop depends on `json >= 2.3`,
# so without this pin adding the linter resolves json 3 and every request --
# and every `to_json` -- raises ArgumentError: unknown keyword: quirks_mode.
# Ruby 3.2 ships 2.6.3 as a default gem; this just keeps the resolver there.
gem "json", "~> 2.6"

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
