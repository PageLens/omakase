class Click < ActiveRecord::Base
  belongs_to :link
  belongs_to :user

  before_create {self.clicked_at ||= Time.zone.now}
end
