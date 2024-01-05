# frozen_string_literal: true

module Sms
  # Delivers via Twilio's REST API.
  #
  # Credentials come from the environment first and Rails encrypted
  # credentials second, so a deployment can supply them either way and a
  # checkout with no config/master.key still boots.
  class TwilioAdapter
    # Twilio's code for "the 'To' number is not a valid phone number".
    INVALID_PHONE_NUMBER = 21_211

    class << self
      def account_sid = setting(:account_sid, "TWILIO_ACCOUNT_SID")
      def auth_token   = setting(:auth_token, "TWILIO_AUTH_TOKEN")
      def from_number  = setting(:from_number, "TWILIO_FROM_NUMBER")

      def configured?
        account_sid.present? && auth_token.present? && from_number.present?
      end

      private

      def setting(credential_key, env_key)
        ENV[env_key].presence || Rails.application.credentials.dig(:twilio, credential_key).presence
      end
    end

    def initialize(client: nil, from_number: self.class.from_number)
      @client = client
      @from_number = from_number
    end

    def deliver(to:, body:)
      client.messages.create(body: body, from: @from_number, to: to)
      Result.success
    rescue ::Twilio::REST::RestError => e
      Result.public_send(twilio_severity(e), twilio_message(e))
    rescue ::Twilio::REST::TwilioError, IOError, SystemCallError, Timeout::Error => e
      # Connection resets, DNS failures and read timeouts are all worth a retry.
      Result.transient_failure("SMS provider unreachable (#{e.class}: #{e.message})")
    end

    private

    def client
      @client ||= ::Twilio::REST::Client.new(self.class.account_sid, self.class.auth_token)
    end

    # 5xx from Twilio is worth retrying; a 4xx means the request itself is wrong.
    def twilio_severity(error)
      error.status_code.to_i >= 500 ? :transient_failure : :permanent_failure
    end

    def twilio_message(error)
      return "That phone number is not valid." if error.code == INVALID_PHONE_NUMBER

      "SMS provider rejected the message (Twilio error #{error.code})."
    end
  end
end
