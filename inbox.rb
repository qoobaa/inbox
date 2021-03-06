require "sinatra"
require "haml"
require "dm-core"
require "dm-validations"
require "dm-timestamps"
require "action_mailer"  # using TMail
require "lib/pop_ssl"    # "net/pop" doesn't support SSL

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3::memory:")

class Mail
  include DataMapper::Resource

  USER = "j78r6b29"
  PASSWORD = "d23occh8"

  property :id, Serial
  property :subject, String
  property :uidl, String, :nullable => false
  property :sender, String
  property :body, Text
  property :created_at, DateTime

  belongs_to :recipient

  validates_present :recipient
  validates_is_unique :uidl, :scope => :recipient_id

  def self.download
    n_mails = nil
    Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
    Net::POP3.start("pop.gmail.com", 995, USER, PASSWORD) do |pop|
      n_mails = pop.n_mails
      pop.mails.each do |mail|
        tmail = TMail::Mail.parse(mail.top(64))
        tmail.to.each do |address|
          create(:recipient => Recipient.first(:address => address),
                 :sender => tmail.from.first,
                 :body => tmail.body,
                 :subject => tmail.subject,
                 :uidl => mail.uidl)
        end
        mail.delete
      end
    end
    n_mails
  end
end

class Recipient
  include DataMapper::Resource

  property :id, Serial
  property :address, String, :nullable => false
  property :created_at, DateTime
  has n, :mails

  validates_present :address
  validates_is_unique :address

  before :valid?, :generate_address
  before :destroy, :destroy_mails

  def generate_address
    self.address ||= "#{Mail::USER}+#{token}@gmail.com"
  end

  def destroy_mails
    mails.all.destroy!
  end

  def token
    address ? address[/\+.*@/][1..-2] : (100_000_000_000 + rand(1_000_000_000)).to_s(36)
  end
end

DataMapper.auto_migrate!

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

get "/inboxautocomplete.user.js" do
  @recipient = Recipient.get(session[:recipient_id])
  content_type "text/javascript"
  erb :script
end
