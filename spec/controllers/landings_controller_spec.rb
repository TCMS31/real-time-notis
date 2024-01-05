# frozen_string_literal: true

require "rails_helper"

# Narrow unit coverage of the controller itself. End-to-end authentication,
# cross-user authorisation and the allow-list are covered in
# spec/requests/messages_spec.rb.
RSpec.describe LandingsController do
  let(:user) { create(:user) }

  describe "#index" do
    it "renders the dashboard for a signed-in user" do
      sign_in user
      get :index

      expect(response).to render_template(:index)
      expect(assigns(:message_keys)).to eq(Sms::MessageCatalog.user_triggerable_keys)
    end

    it "redirects a signed-out visitor to the sign-in page" do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "#create" do
    before { sign_in user }

    it "redirects with a notice naming the message and the masked number" do
      post :create, params: { message_key: "transaction_success" }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("Send transaction success SMS")
      expect(flash[:notice]).to include(user.masked_phone_number)
    end

    it "redirects with an alert when the key is not in the catalogue" do
      post :create, params: { message_key: "anything at all" }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
      expect(flash[:notice]).to be_blank
    end

    # A web request must never wait on the SMS provider.
    it "does not deliver inline" do
      allow(Sms::Deliverer).to receive(:deliver)

      post :create, params: { message_key: "transaction_declined" }

      expect(Sms::Deliverer).not_to have_received(:deliver)
    end
  end
end
