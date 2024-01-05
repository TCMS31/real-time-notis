# frozen_string_literal: true

module Sms
  # The port every caller talks to. Adapters are registered by name, so adding
  # a second provider is a new adapter class plus one +register+ call — no
  # caller changes and no conditionals sprayed through the app.
  #
  #   Sms::Deliverer.register("vonage") { Sms::VonageAdapter.new }
  #   SMS_ADAPTER=vonage bin/rails server
  #
  # The active adapter is named by +Rails.configuration.x.sms.adapter+, which
  # config/initializers/sms.rb derives from the environment.
  module Deliverer
    UnknownAdapter = Class.new(ArgumentError)

    @registry = {}

    class << self
      attr_reader :registry

      def register(name, &factory)
        raise ArgumentError, "a factory block is required" unless factory

        @registry[name.to_s] = factory
      end

      def registered_names = @registry.keys.sort

      def deliver(to:, body:)
        adapter.deliver(to: to, body: body)
      end

      # Built fresh per call: adapters are cheap, and memoizing one would
      # outlive a code reload in development and a stub in tests.
      def adapter(name = configured_adapter_name)
        factory = @registry.fetch(name.to_s) do
          raise UnknownAdapter, "unknown SMS adapter #{name.inspect}; registered: #{registered_names.join(', ')}"
        end
        factory.call
      end

      # SMS_ADAPTER wins when set; otherwise pick Twilio if it is fully
      # configured and fall back to the log adapter if it is not. Resolved
      # lazily so no autoloaded constant is touched during initialization.
      def configured_adapter_name
        Rails.configuration.x.sms.adapter.presence || default_adapter_name
      end

      def default_adapter_name
        TwilioAdapter.configured? ? "twilio" : "log"
      end
    end
  end
end
