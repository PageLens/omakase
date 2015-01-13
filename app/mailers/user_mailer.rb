class UserMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.folder_invitation.subject
  #
  def folder_invitation(folder_invitation_id)
    @folder_invitation = FolderInvitation.find(folder_invitation_id)
    @body_class = body_class
    mail to: @folder_invitation.email, from: sender(@folder_invitation.user), reply_to: @folder_invitation.user.email
  end

private
  def body_class
    "#{mailer_name.underscore.dasherize} #{action_name.underscore.dasherize}"
  end

  # Returns String to use for from.
  def sender(user=nil)
    if user
      "#{user.name || user.username} <#{CONFIG[:mailer][:notification_email]}>"
    else
      "#{t('global.pagelens')} <#{CONFIG[:mailer][:notification_email]}>"
    end
  end
end
