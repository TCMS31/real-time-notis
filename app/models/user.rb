# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # E.164: a leading +, a non-zero country code, 10 to 15 digits in total.
  # Twilio rejects anything else, so there is no point storing it.
  PHONE_NUMBER_FORMAT = /\A\+[1-9]\d{9,14}\z/

  validates :name, presence: true, length: { maximum: 100 }
  validates :phone_number,
            presence: true,
            format: {
              with: PHONE_NUMBER_FORMAT,
              message: "must be in E.164 format, for example +14155552671"
            }

  # after_commit, not after_create: the welcome SMS is sent once the row is
  # durably committed, and it is enqueued rather than sent inline. A provider
  # outage therefore cannot roll back — or 500 — a sign-up that has already
  # succeeded.
  after_commit :enqueue_welcome_sms, on: :create

  # Phone numbers are PII; show the user enough to recognise their own number
  # without echoing it into flash messages, logs or screenshots.
  def masked_phone_number
    Sms::LogAdapter.mask(phone_number)
  end

  private

  def enqueue_welcome_sms
    SendSmsJob.perform_later(user_id: id, message_key: Sms::MessageCatalog::WELCOME.to_s)
  end
end
