# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "validations" do
    it "accepts a well-formed record" do
      expect(build(:user)).to be_valid
    end

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:phone_number) }

    # The DB columns are NOT NULL with no default, so without these model
    # validations a blank name raised a PG::NotNullViolation (a 500) instead
    # of rendering a form error.
    it "reports a blank name rather than hitting the NOT NULL constraint" do
      user = build(:user, name: "")
      expect { user.save }.not_to raise_error
      expect(user.errors[:name]).to be_present
    end

    describe "phone_number format" do
      it "accepts E.164" do
        expect(build(:user, phone_number: "+14155552671")).to be_valid
      end

      it "rejects a number with no country code" do
        user = build(:user, phone_number: "4155552671")
        expect(user).not_to be_valid
        expect(user.errors[:phone_number].join).to match(/E\.164/)
      end

      # The previous regex was /\A\+\d{2}\d{9,15}\z/, which allowed up to 17
      # digits. E.164 caps the whole number at 15, and Twilio rejects longer.
      it "rejects a number longer than E.164 allows" do
        expect(build(:user, phone_number: "+1234567890123456")).not_to be_valid
      end

      it "rejects a leading zero country code" do
        expect(build(:user, phone_number: "+0415555267")).not_to be_valid
      end
    end
  end

  describe "#masked_phone_number" do
    it "shows only the first and last three digits" do
      user = build(:user, phone_number: "+14155552671")
      expect(user.masked_phone_number).to eq("+14••••••671")
    end
  end

  describe "the welcome SMS" do
    it "is enqueued once the row is committed" do
      expect { create(:user) }
        .to have_enqueued_job(SendSmsJob)
        .with(hash_including(message_key: "welcome"))
    end

    it "is not enqueued when the record is invalid" do
      expect { build(:user, phone_number: "nope").save }.not_to have_enqueued_job(SendSmsJob)
    end

    it "is not enqueued again when the user is updated" do
      user = create(:user)
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear

      expect { user.update!(name: "Renamed") }.not_to have_enqueued_job(SendSmsJob)
    end

    # The regression this app was built around: the welcome SMS used to be an
    # after_create that raised ActiveRecord::Rollback when the provider
    # failed, so an outage silently discarded the sign-up -- and User.create!
    # returned an unpersisted record without raising.
    it "does not roll the user back when delivery fails" do
      allow(Sms::Deliverer).to receive(:deliver)
        .and_return(Sms::Result.permanent_failure("provider down"))

      user = nil
      expect { user = perform_enqueued_jobs { create(:user) } }.to change(described_class, :count).by(1)
      expect(user).to be_persisted
      expect(described_class.find_by(id: user.id)).to be_present
    end

    it "does not raise out of create! when delivery fails" do
      allow(Sms::Deliverer).to receive(:deliver)
        .and_return(Sms::Result.permanent_failure("provider down"))

      expect { perform_enqueued_jobs { create(:user) } }.not_to raise_error
    end
  end
end
