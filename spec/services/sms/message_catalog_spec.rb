# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sms::MessageCatalog do
  describe ".user_triggerable?" do
    it "accepts a catalogued, user-facing key given as a string or a symbol" do
      expect(described_class).to be_user_triggerable("transaction_success")
      expect(described_class).to be_user_triggerable(:transaction_success)
    end

    # :welcome is system-only. A user must not be able to replay it.
    it "rejects the system-only welcome message" do
      expect(described_class).not_to be_user_triggerable(:welcome)
    end

    it "rejects anything not in the catalogue" do
      expect(described_class).not_to be_user_triggerable("arbitrary text")
      expect(described_class).not_to be_user_triggerable(nil)
      expect(described_class).not_to be_user_triggerable("")
    end
  end

  describe ".render" do
    it "personalises the catalogued body" do
      expect(described_class.render(:transaction_success, name: "Ada"))
        .to eq("Hey Ada, your transaction has been delivered!")
    end

    it "refuses an unknown key instead of sending free text" do
      expect { described_class.render("DROP TABLE users", name: "Ada") }
        .to raise_error(described_class::UnknownMessage)
    end
  end

  it "keeps every catalogued entry complete" do
    described_class::MESSAGES.each_value do |entry|
      expect(entry[:body]).to be_present
      expect(entry[:label]).to be_present
    end
  end
end
