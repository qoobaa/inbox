require "sinatra"
require "haml"
require "dm-core"
require "dm-validations"
require "dm-timestamps"
require "action_mailer"
require "lib/pop_ssl"
require "models"

enable :sessions

get "/" do
  Mail.download
  @recipient = Recipient.get(session[:recipient_id])
  @mails = @recipient.mails if @recipient
  haml :home
end

post "/recipient" do
  @recipient = Recipient.create
  session[:recipient_id] = @recipient.id
  redirect "/"
end

delete "/recipient" do
  @recipient = Recipient.get(session[:recipient_id])
  @recipient.destroy if @recipient
  session.clear
  redirect "/"
end
