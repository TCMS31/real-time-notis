require 'rails_helper'

RSpec.describe LandingsController, type: :controller do
  let!(:user) { create(:user) }

  describe '#index' do
    context 'when user is signed in' do
      before do
        sign_in user
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to the sign-in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe '#create' do
    before { sign_in user }

    context 'with valid parameters' do
      it 'sends SMS and redirects to root_path with notice' do
        allow_any_instance_of(Twilio::SendSmsService).to receive(:send_msg).and_return(status: true)

        post :create, params: { msg: 'Test message' }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Test message')
      end
    end

    context 'with invalid parameters' do
      it 'does not send SMS and redirects to root_path with alert' do
        allow_any_instance_of(Twilio::SendSmsService).to receive(:send_msg).and_return(status: false, msg: 'Failed to send')

        post :create, params: { msg: 'Invalid message' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Failed to send')
      end
    end
  end
end
