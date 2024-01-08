FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'test123' }
    name { Faker::Name.name }
    phone_number {'+12486020500'}
  end
end
