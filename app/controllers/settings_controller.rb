class SettingsController < Devise::RegistrationsController
  force_ssl if: :ssl_configured?

  def edit
    @user = current_user
  end

  def update
    @user = User.find(current_user.id)
    account_update_params = devise_parameter_sanitizer.sanitize(:account_update)

    successfully_updated = if needs_password?(@user, account_update_params)
      if @user.has_password?
        @user.update_with_password(account_update_params)
      else
        account_update_params.delete("current_password")
        @user.update_attributes(account_update_params)
      end
    else
      # remove the virtual current_password attribute
      # update_without_password doesn't know how to ignore it
      account_update_params.delete("current_password")
      @user.update_without_password(account_update_params)
    end
    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case their password changed
      sign_in @user, :bypass => true
      redirect_to after_update_path_for(@user)
    else
      render "edit"
    end
  end

private
  # check if we need password to update user data
  def needs_password?(user, account_update_params)
    account_update_params[:password].present? ||
    account_update_params[:password_confirmation].present?
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
