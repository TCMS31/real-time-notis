# frozen_string_literal: true

# Wires the SMS adapters into Sms::Deliverer.
#
# `to_prepare` runs after each code reload, so the registry survives
# development reloading. Nothing here performs I/O and no constant is
# autoloaded while the application is still initializing.
Rails.application.config.to_prepare do
  Sms::Deliverer.register("twilio") { Sms::TwilioAdapter.new }
  Sms::Deliverer.register("log")    { Sms::LogAdapter.new }
end

# Precedence: an explicit config.x.sms.adapter set by config/environments
# (the test environment pins "log") wins, then SMS_ADAPTER, then auto-select
# in Sms::Deliverer -- Twilio when credentials are present, the log adapter
# when they are not, so a fresh checkout boots and works end to end.
Rails.application.config.x.sms.adapter ||= ENV["SMS_ADAPTER"].presence
