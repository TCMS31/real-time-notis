Twilio.configure do |config|
  config.account_sid = Rails.application.credentials.dig(:twilio, :account_sid)
  config.auth_token = Rails.application.credentials.dig(:twilio, :auth_token)
end
