class EmailDelivery < ActiveRecord::Base
  belongs_to :email_stat
  before_create :generate_tracking_code

private
  def generate_tracking_code
    self.tracking_code = SecureRandom.urlsafe_base64(16).gsub('-', '_')
  end
end
