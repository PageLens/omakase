class EmailStat < ActiveRecord::Base
  STATUS = { ok: 'ok', bounce: 'bounce' }

  has_many :email_deliveries, dependent: :destroy

  validates_presence_of :email, on: :create
  before_create :generate_tag
  before_create :set_default_status

  def email=(e)
    write_attribute(:email, e.downcase) if e.present?
  end

private
  def generate_tag
    self.tag ||= SecureRandom.urlsafe_base64(16).gsub('-', '_')
  end

  def set_default_status
    self.status ||= STATUS[:ok]
  end
end
