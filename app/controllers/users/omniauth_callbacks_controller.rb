class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  def facebook
    auth(:facebook)
    # # You need to implement the method below in your model (e.g. app/models/user.rb)
    # @user = User.find_for_facebook_oauth(request.env["omniauth.auth"])

    # if @user.persisted?
    #   sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
    #   set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    # else
    #   session["devise.facebook_data"] = request.env["omniauth.auth"]
    #   redirect_to new_user_registration_url
    # end
  end

  def twitter
    auth(:twitter)
  end

protected
  def auth(provider)
    auth_hash = request.env['omniauth.auth']
    @user = User.find_for_omniauth(provider, auth_hash, current_user)

    if @user.persisted?
      remember_me(@user)
      sign_in_and_redirect @user, :event => :authentication
    else
      session['devise.omniauth'] = auth_hash.except('extra')
      redirect_to new_user_registration_url
    end
  end
end
