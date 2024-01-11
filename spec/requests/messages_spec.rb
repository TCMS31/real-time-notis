# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sending a message" do
  let(:sender) { create(:user, name: "Ada", phone_number: "+14155550001") }
  let(:other_user) { create(:user, name: "Grace", phone_number: "+14155550002") }

  describe "authentication" do
    it "redirects a signed-out visitor away from the dashboard" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "refuses to enqueue anything for a signed-out visitor" do
      expect { post messages_path, params: { message_key: "transaction_success" } }
        .not_to have_enqueued_job(SendSmsJob)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "authorisation" do
    before { sign_in sender }

    it "enqueues the message for the signed-in user" do
      expect { post messages_path, params: { message_key: "transaction_success" } }
        .to have_enqueued_job(SendSmsJob)
        .with(hash_including(user_id: sender.id, message_key: "transaction_success"))
    end

    # The cross-user check: a crafted user_id must not redirect the SMS to
    # somebody else's phone. The controller reads current_user and nothing else.
    it "ignores a user_id supplied in params and texts only the signed-in user" do
      expect do
        post messages_path, params: {
          message_key: "transaction_success",
          user_id: other_user.id
        }
      end.to have_enqueued_job(SendSmsJob).with(hash_including(user_id: sender.id))
    end

    it "ignores a phone_number supplied in params" do
      perform_enqueued_jobs do
        allow(Sms::Deliverer).to receive(:deliver).and_return(Sms::Result.success)

        post messages_path, params: {
          message_key: "transaction_success",
          phone_number: "+19998887777"
        }

        expect(Sms::Deliverer).to have_received(:deliver)
          .with(hash_including(to: "+14155550001"))
      end
    end
  end

  describe "the message allow-list" do
    before { sign_in sender }

    # Previously the controller passed params[:msg] straight to Twilio, so a
    # signed-in user could send any text they liked at the operator's expense.
    it "refuses free text and enqueues nothing" do
      expect do
        post messages_path, params: { message_key: "Call this number to claim your prize" }
      end.not_to have_enqueued_job(SendSmsJob)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it "refuses the system-only welcome message" do
      expect { post messages_path, params: { message_key: "welcome" } }
        .not_to have_enqueued_job(SendSmsJob)
    end

    it "refuses a missing key" do
      expect { post messages_path, params: {} }.not_to have_enqueued_job(SendSmsJob)
    end
  end

  describe "the dashboard" do
    before { sign_in sender }

    it "renders every user-triggerable message and masks the number" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Send transaction success SMS")
      expect(response.body).to include("Send transaction declined SMS")
      expect(response.body).to include("+14••••••001")
      expect(response.body).not_to include("+14155550001")
    end
  end
end
