class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(record, record.confirmation_token || "token")
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(record, record.reset_password_token || "token")
  end

private
  def record
    User.first || FactoryGirl.create(:user)
  end
end
