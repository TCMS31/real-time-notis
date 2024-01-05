# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Signing up" do
  let(:params) do
    {
      user: {
        name: "Ada Lovelace",
        phone_number: "+14155552671",
        email: "ada@example.com",
        password: "correct horse battery",
        password_confirmation: "correct horse battery"
      }
    }
  end

  it "creates the account and queues the welcome SMS" do
    expect { post user_registration_path, params: params }
      .to change(User, :count).by(1)
      .and have_enqueued_job(SendSmsJob).with(hash_including(message_key: "welcome"))

    expect(response).to redirect_to(root_path)
  end

  # The original defect: the welcome SMS ran inline in an after_create, so a
  # Twilio outage rolled the transaction back and the sign-up vanished.
  it "still creates the account when the SMS provider is down" do
    allow(Sms::Deliverer).to receive(:deliver)
      .and_return(Sms::Result.transient_failure("provider unreachable"))

    expect { post user_registration_path, params: params }.to change(User, :count).by(1)

    # Turbo-aware Devise redirects with 303, not a 500 and not a rollback.
    expect(response).to have_http_status(:see_other)
    expect(User.find_by(email: "ada@example.com")).to be_present
  end

  it "rejects a phone number that is not E.164 without creating anything" do
    params[:user][:phone_number] = "555-1234"

    expect { post user_registration_path, params: params }.not_to change(User, :count)
    expect(response.body).to match(/E\.164/)
  end
end
