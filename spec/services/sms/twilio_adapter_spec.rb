# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sms::TwilioAdapter do
  subject(:adapter) { described_class.new(client: client, from_number: "+15550000000") }

  let(:client) { Twilio::REST::Client.new("AC" + ("0" * 32), "test-token") }
  let(:messages_url) { %r{https://api\.twilio\.com/2010-04-01/Accounts/AC0+/Messages\.json} }

  describe ".configured?" do
    it "is false unless all three settings are present" do
      allow(described_class).to receive_messages(
        account_sid: "AC123", auth_token: "tok", from_number: nil
      )
      expect(described_class).not_to be_configured
    end

    it "prefers the environment over encrypted credentials" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TWILIO_ACCOUNT_SID").and_return("AC-from-env")

      expect(described_class.account_sid).to eq("AC-from-env")
    end
  end

  describe "#deliver" do
    it "returns success when Twilio accepts the message" do
      stub_request(:post, messages_url).to_return(
        status: 201, body: { sid: "SM1", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect(adapter.deliver(to: "+14155552671", body: "hi")).to be_success
    end

    it "treats an unroutable number as permanent and says so in plain language" do
      stub_request(:post, messages_url).to_return(
        status: 400,
        body: { code: 21_211, message: "The 'To' number is not a valid phone number." }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      result = adapter.deliver(to: "+19999999999", body: "hi")
      expect(result).to be_failure
      expect(result).not_to be_retryable
      expect(result.error_message).to eq("That phone number is not valid.")
    end

    it "treats a provider 5xx as retryable" do
      stub_request(:post, messages_url).to_return(
        status: 503, body: { code: 20_500, message: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      result = adapter.deliver(to: "+14155552671", body: "hi")
      expect(result).to be_retryable
    end

    it "treats a connection failure as retryable rather than raising into the caller" do
      stub_request(:post, messages_url).to_raise(Errno::ECONNRESET)

      result = adapter.deliver(to: "+14155552671", body: "hi")
      expect(result).to be_retryable
      expect(result.error_message).to match(/unreachable/)
    end
  end
end
