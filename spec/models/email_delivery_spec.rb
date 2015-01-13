require 'rails_helper'

RSpec.describe EmailDelivery, :type => :model do
  let(:email_stat) {create(:email_stat)}

  it "should generate tracking code on create" do
    email_delivery = EmailDelivery.create!(email_stat: email_stat)
    expect(email_delivery.tracking_code).to be_present
  end
end
