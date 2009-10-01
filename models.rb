# ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database =>  "tempmail.sqlite3")

dbconfig = YAML.load(File.read("config/database.yml"))
ActiveRecord::Base.establish_connection(dbconfig["production"])

ActiveRecord::Schema.define do
  create_table "mails", :force => true do |t|
    t.belongs_to "recipient"
    t.string "sender", "subject", "uidl"
    t.text "body"
    t.datetime "created_at", "updated_at"
  end

  create_table "recipients", :force => true do |t|
    t.string "address"
    t.datetime "created_at", "updated_at"
  end
end

class Mail < ActiveRecord::Base
  belongs_to :recipient
  validates_presence_of :recipient
  validates_uniqueness_of :uidl, :scope => :recipient_id
  def self.download
    n_mails = nil
    Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
    Net::POP3.start("pop.gmail.com", 995, "j78r6b29", "d23occh8") do |pop|
      n_mails = pop.n_mails
      pop.mails.each do |mail|
        tmail = TMail::Mail.parse(mail.top(64))
        tmail.to.each do |address|
          create(:recipient => Recipient.find_by_address(address),
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

class Recipient < ActiveRecord::Base
  has_many :mails, :dependent => :destroy
  validates_presence_of :address
  validates_uniqueness_of :address
  before_validation_on_create :generate_address
  def generate_address
    token = (100_000_000_000 + rand(1_000_000_000)).to_s(36)
    self.address = "j78r6b29+#{token}@gmail.com"
  end
end
