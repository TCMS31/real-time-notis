# frozen_string_literal: true

# Idempotent demo data. Safe to run repeatedly and in any environment:
# it only ever touches the one demo account.
#
#   bin/rails db:seed
#
# The welcome SMS is enqueued as usual; with no Twilio credentials set the
# log adapter handles it, so seeding never makes a network call.
demo = User.find_or_initialize_by(email: ENV.fetch("SEED_EMAIL", "demo@example.com"))

if demo.new_record?
  demo.assign_attributes(
    name: ENV.fetch("SEED_NAME", "Ada Lovelace"),
    phone_number: ENV.fetch("SEED_PHONE", "+14155552671"),
    password: ENV.fetch("SEED_PASSWORD", "correct horse battery"),
    password_confirmation: ENV.fetch("SEED_PASSWORD", "correct horse battery")
  )
  demo.save!
  Rails.logger.info("[seeds] created demo user #{demo.email}")
else
  Rails.logger.info("[seeds] demo user #{demo.email} already present")
end
