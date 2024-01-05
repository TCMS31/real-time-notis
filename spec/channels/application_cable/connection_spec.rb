# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "rejects a visitor who is not signed in" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rejects a session whose user no longer resolves" do
    expect { connect "/cable", env: { "warden" => instance_double(Warden::Proxy, user: nil) } }
      .to have_rejected_connection
  end

  it "identifies the connection by the signed-in user" do
    user = create(:user)

    connect "/cable", env: { "warden" => instance_double(Warden::Proxy, user: user) }

    expect(connection.current_user).to eq(user)
  end
end
