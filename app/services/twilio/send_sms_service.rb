class Twilio::SendSmsService
  attr_reader :message, :contact, :name

  DEFAULT_TWILIO_SENDER = '+17178379358'

  def initialize(contact, message, name)
    @contact = contact
    @message = "Hey #{name}, #{message}"
  end

  def send_msg
    begin
      @client = Twilio::REST::Client.new
      sms = @client.messages.create(
        body: message,
        from:  DEFAULT_TWILIO_SENDER,
        to: contact
      )
      { status: true }
    rescue Twilio::REST::RestError => e
      { status: false, msg: e.code == 21211 ? 'phone number is invalid!' : "Twilio Error: (#{e.message})"}
    end
  end
end
