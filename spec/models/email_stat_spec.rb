require 'rails_helper'

RSpec.describe EmailStat, :type => :model do
  it "should downcase the email address" do
    email_stat = EmailStat.create(:email => "JERRY@pagelens.com")
    expect(email_stat.read_attribute(:email)).to eq "jerry@pagelens.com"
  end

  it "should generate tag on create" do
    email_stat = EmailStat.create(:email => "JERRY@pagelens.com")
    expect(email_stat.tag).to_not be_blank
  end

  it "should set default status to 'ok'" do
    email_stat = EmailStat.create(:email => "JERRY@pagelens.com")
    expect(email_stat.status).to eq EmailStat::STATUS[:ok]
  end
end
