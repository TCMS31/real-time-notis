# frozen_string_literal: true

module Sms
  # Writes the message to the Rails log instead of sending it.
  #
  # This is the adapter the app falls back to when no Twilio credentials are
  # configured, which is what lets the whole application boot, sign users up
  # and exercise both buttons on a laptop with no provider account.
  class LogAdapter
    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def deliver(to:, body:)
      @logger.info("[sms:log] to=#{self.class.mask(to)} body=#{body.inspect}")
      Result.success
    end

    def self.mask(number)
      return "(blank)" if number.blank?

      "#{number[0, 3]}#{'•' * [ number.length - 6, 0 ].max}#{number[-3, 3]}"
    end
  end
end
