class Feedback < ActiveRecord::Base
  validates :email, presence: true, email: true
  validates :description, presence: true, length:{maximum: 5000}
  validates :subject, presence: true
end
