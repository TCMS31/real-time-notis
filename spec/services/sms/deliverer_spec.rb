# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sms::Deliverer do
  it "registers the two built-in adapters at boot" do
    expect(described_class.registered_names).to include("log", "twilio")
  end

  it "delivers through the configured adapter" do
    result = described_class.deliver(to: "+14155552671", body: "hello")
    expect(result).to be_success
  end

  it "builds a fresh adapter per call so a reload cannot leave a stale one behind" do
    expect(described_class.adapter("log")).not_to equal(described_class.adapter("log"))
  end

  it "names the unknown adapter and the valid options when misconfigured" do
    expect { described_class.adapter("carrier-pigeon") }
      .to raise_error(described_class::UnknownAdapter, /carrier-pigeon.*log/m)
  end

  it "requires a factory block when registering" do
    expect { described_class.register("bare") }.to raise_error(ArgumentError)
  end

  describe ".configured_adapter_name" do
    it "falls back to the log adapter when Twilio is not fully configured" do
      allow(Sms::TwilioAdapter).to receive(:configured?).and_return(false)
      allow(Rails.configuration.x.sms).to receive(:adapter).and_return(nil)

      expect(described_class.configured_adapter_name).to eq("log")
    end

    it "selects Twilio once credentials are present" do
      allow(Sms::TwilioAdapter).to receive(:configured?).and_return(true)
      allow(Rails.configuration.x.sms).to receive(:adapter).and_return(nil)

      expect(described_class.configured_adapter_name).to eq("twilio")
    end
  end
end
