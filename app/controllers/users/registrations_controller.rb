class Users::RegistrationsController < Devise::RegistrationsController

protected
  def update_resource(resource, params)
    if resource.has_password?
      resource.update_with_password(params)
    else
      resource.update(params.except(:current_password))
    end
  end
end
