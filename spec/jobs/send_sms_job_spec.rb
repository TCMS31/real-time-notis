# frozen_string_literal: true

require "rails_helper"

RSpec.describe SendSmsJob do
  let(:user) { create(:user, name: "Ada", phone_number: "+14155552671") }

  it "renders the catalogued body and sends it to the user's own number" do
    allow(Sms::Deliverer).to receive(:deliver).and_return(Sms::Result.success)

    described_class.perform_now(user_id: user.id, message_key: "transaction_success")

    expect(Sms::Deliverer).to have_received(:deliver).with(
      to: "+14155552671",
      body: "Hey Ada, your transaction has been delivered!"
    )
  end

  it "raises a transient error out of perform when the provider is unreachable" do
    allow(Sms::Deliverer).to receive(:deliver)
      .and_return(Sms::Result.transient_failure("provider unreachable"))

    # perform is called directly so the retry_on handler does not swallow it.
    job = described_class.new(user_id: user.id, message_key: "welcome")
    expect { job.perform(user_id: user.id, message_key: "welcome") }
      .to raise_error(Sms::TransientError, /provider unreachable/)
  end

  it "re-enqueues itself rather than surfacing a provider outage to the caller" do
    user # created up front: creating it enqueues the welcome job
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    allow(Sms::Deliverer).to receive(:deliver)
      .and_return(Sms::Result.transient_failure("provider unreachable"))

    expect { described_class.perform_now(user_id: user.id, message_key: "welcome") }
      .to have_enqueued_job(described_class)
  end

  it "logs and drops a permanent failure instead of retrying forever" do
    allow(Sms::Deliverer).to receive(:deliver)
      .and_return(Sms::Result.permanent_failure("That phone number is not valid."))
    allow(Rails.logger).to receive(:warn)

    expect { described_class.perform_now(user_id: user.id, message_key: "welcome") }
      .not_to raise_error
  end

  it "discards the job when the user no longer exists" do
    missing_id = user.id
    user.destroy!

    expect { described_class.perform_now(user_id: missing_id, message_key: "welcome") }
      .not_to raise_error
  end

  it "discards a job carrying a key that is not in the catalogue" do
    expect { described_class.perform_now(user_id: user.id, message_key: "not_a_message") }
      .not_to raise_error
  end

  it "is configured to retry transient failures with backoff" do
    expect(described_class.rescue_handlers.map(&:first)).to include("Sms::TransientError")
  end
end
