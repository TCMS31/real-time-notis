# frozen_string_literal: true

module Sms
  # Raised by SendSmsJob so Active Job's retry machinery takes over. Adapters
  # never raise this themselves — they return a retryable Result and let the
  # job decide.
  class TransientError < StandardError; end
end
