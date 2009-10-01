# ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database =>  "tempmail.sqlite3")

ActiveRecord::Base.establish_connection(ENV['DATABASE_URI'])

ActiveRecord::Schema.define do
  create_table "mails", :force => true do |t|
    t.integer  "recipient_id"
    t.string   "sender"
    t.string   "subject"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uidl"
  end

  create_table "recipients", :force => true do |t|
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end

class Mail < ActiveRecord::Base
  belongs_to :recipient
  validates_presence_of :recipient
  validates_uniqueness_of :uidl, :scope => :recipient_id
  def self.download
    pop = Net::POP3.new("pop.gmail.com", 995)
    pop.enable_ssl
    pop.start("j78r6b29", "d23occh8")
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
    pop.finish
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
