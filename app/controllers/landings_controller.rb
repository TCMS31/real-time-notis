# frozen_string_literal: true

# The single signed-in screen: it lists the messages a user may trigger and
# enqueues the one they picked.
class LandingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @message_keys = Sms::MessageCatalog.user_triggerable_keys
  end

  def create
    key = params[:message_key]

    # Allow-list, not free text. The body is resolved server-side from the
    # catalogue, so a crafted request cannot choose what gets sent.
    unless Sms::MessageCatalog.user_triggerable?(key)
      return redirect_to(root_path, alert: "That message is not one you can send.")
    end

    # Always the signed-in user's own number — never a number from params.
    SendSmsJob.perform_later(user_id: current_user.id, message_key: key.to_s)

    redirect_to root_path,
                notice: "#{Sms::MessageCatalog.label_for(key)} queued for #{current_user.masked_phone_number}."
  end
end
