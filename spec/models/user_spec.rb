# spec/models/user_spec.rb

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:valid_user_attributes) do
    {
      email: 'test@example.com',
      password: 'password123',
      phone_number: '+1234567890123',
      name: 'Test User'
    }
  end

  it 'is valid with valid attributes' do
    user = User.new(valid_user_attributes)
    expect(user).to be_valid
  end

  it 'is not valid without a valid phone_number format' do
    user = User.new(valid_user_attributes.merge(phone_number: '1234567890'))
    expect(user).not_to be_valid
    expect(user.errors[:phone_number]).to include('invalid!')
  end

  it 'triggers send_welcome_sms after user creation' do
    user = User.create(valid_user_attributes)
    expect(user).to be_valid

    expect_any_instance_of(Twilio::SendSmsService).to receive(:send_msg).and_return(status: true)
    user.save
  end

  it 'adds an error to base and rolls back transaction if send_welcome_sms fails' do
    user = User.new(valid_user_attributes)
    allow_any_instance_of(Twilio::SendSmsService).to receive(:send_msg).and_return(status: false, msg: 'Error')

    expect { user.save }.to change(User, :count).by(0)
    expect(user.errors[:base]).to include('Error')
  end

  it 'does not rollback transaction if send_welcome_sms succeeds' do
    user = User.new(valid_user_attributes)
    allow_any_instance_of(Twilio::SendSmsService).to receive(:send_msg).and_return(status: true)

    expect { user.save }.to change(User, :count).by(1)
    expect(user.errors).to be_empty
  end
end
