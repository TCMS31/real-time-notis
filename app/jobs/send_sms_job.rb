# frozen_string_literal: true

# Delivers one catalogued message to one user, off the request thread.
#
# Nothing in a web request waits on the SMS provider: a Twilio outage slows
# nothing down, fails no sign-up and returns no 500. Transient provider
# failures are retried with backoff; permanent ones (an unroutable number)
# are logged once and dropped, because retrying them cannot help.
class SendSmsJob < ApplicationJob
  queue_as :default

  retry_on Sms::TransientError, wait: :polynomially_longer, attempts: 5

  # The user was deleted between enqueue and perform; there is nobody to text.
  discard_on ActiveRecord::RecordNotFound
  # A key that is not in the catalogue will never become one on retry.
  discard_on Sms::MessageCatalog::UnknownMessage

  def perform(user_id:, message_key:)
    user = User.find(user_id)
    body = Sms::MessageCatalog.render(message_key, name: user.name)
    result = Sms::Deliverer.deliver(to: user.phone_number, body: body)

    return if result.success?

    if result.retryable?
      raise Sms::TransientError, result.error_message
    else
      logger.warn(
        "[sms] dropping #{message_key} for user #{user_id}: #{result.error_message}"
      )
    end
  end
end
