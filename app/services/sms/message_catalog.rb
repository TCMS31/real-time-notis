# frozen_string_literal: true

module Sms
  # The complete server-side catalogue of messages this application may send.
  #
  # Callers pass a symbolic key; the body is looked up here. A request can
  # therefore never dictate the text of an outbound SMS, and the set of
  # messages a signed-in user may trigger is an allow-list rather than
  # whatever arrives in +params+.
  module MessageCatalog
    UnknownMessage = Class.new(ArgumentError)

    WELCOME = :welcome
    TRANSACTION_SUCCESS = :transaction_success
    TRANSACTION_DECLINED = :transaction_declined

    MESSAGES = {
      WELCOME => {
        body: "welcome to Real-time Notis.",
        label: "Welcome",
        user_triggerable: false
      },
      TRANSACTION_SUCCESS => {
        body: "your transaction has been delivered!",
        label: "Send transaction success SMS",
        user_triggerable: true
      },
      TRANSACTION_DECLINED => {
        body: "your transaction was declined.",
        label: "Send transaction declined SMS",
        user_triggerable: true
      }
    }.freeze

    class << self
      def keys = MESSAGES.keys

      # Keys a signed-in user is allowed to trigger from the UI. +:welcome+ is
      # deliberately excluded: it is sent by the system on sign-up only.
      def user_triggerable_keys
        MESSAGES.select { |_key, entry| entry[:user_triggerable] }.keys
      end

      def user_triggerable?(key)
        user_triggerable_keys.include?(normalize(key))
      end

      def label_for(key) = fetch(key).fetch(:label)

      # Renders the personalised body sent to the provider.
      def render(key, name:)
        "Hey #{name}, #{fetch(key).fetch(:body)}"
      end

      def fetch(key)
        MESSAGES.fetch(normalize(key)) { raise UnknownMessage, "unknown message key: #{key.inspect}" }
      end

      private

      def normalize(key)
        return nil if key.nil? || key.to_s.empty?

        key.to_s.to_sym
      end
    end
  end
end
