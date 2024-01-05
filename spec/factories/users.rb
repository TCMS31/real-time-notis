# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "correct horse battery" }
    name { Faker::Name.name }
    # Deterministic, valid E.164. Faker's phone numbers are not E.164 and
    # would fail the model's format validation at random.
    sequence(:phone_number) { |n| format("+1415555%<suffix>04d", suffix: n % 10_000) }
  end
end
