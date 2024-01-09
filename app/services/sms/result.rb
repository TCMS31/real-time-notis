# frozen_string_literal: true

module Sms
  # Value object returned by every {Sms} adapter.
  #
  # Adapters never raise for a delivery failure: a provider being unreachable
  # is an expected outcome, not an exceptional one. They classify the failure
  # instead, and the caller decides whether to retry.
  class Result
    attr_reader :error_message

    def self.success
      new(success: true)
    end

    # A failure worth retrying: timeouts, connection resets, provider 5xx.
    def self.transient_failure(message)
      new(success: false, error_message: message, retryable: true)
    end

    # A failure that will never succeed on retry: an unroutable number,
    # a rejected body, bad credentials.
    def self.permanent_failure(message)
      new(success: false, error_message: message, retryable: false)
    end

    def initialize(success:, error_message: nil, retryable: false)
      @success = success
      @error_message = error_message
      @retryable = retryable
      freeze
    end

    def success? = @success
    def failure? = !@success
    def retryable? = @retryable

    def to_s
      success? ? "success" : "failure(#{retryable? ? 'transient' : 'permanent'}): #{error_message}"
    end
  end
end
