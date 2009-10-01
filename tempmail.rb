require "sinatra"
require "haml"
require "action_mailer"
require "active_record"
require "net/pop"
require "models"

enable :sessions

get "/" do
  Mail.download
  @recipient = Recipient.find_by_id(session[:recipient_id])
  @mails = @recipient.mails if @recipient
  haml :home
end

post "/recipient" do
  @recipient = Recipient.create
  session[:recipient_id] = @recipient.id
  redirect "/"
end

delete "/recipient" do
  Recipient.destroy(session[:recipient_id])
  redirect "/"
end
