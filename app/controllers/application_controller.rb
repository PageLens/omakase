class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :set_time_zone

  rescue_from ActiveRecord::RecordNotFound do |error|
    render_status(:not_found)
  end

protected
  def current_user_json
    render_to_string(template: 'users/_user.json.jbuilder', locals: {user: current_user}) if user_signed_in?
  end
  helper_method :current_user_json

  # Protected: Creates a Paging.
  #
  # collection - WillPaginate Collection Array.
  #
  # Returns the response headers
  #
  def headers_for_collection(collection)
    links = []
    links << "<#{url_for(params.merge(page: collection.previous_page))}>; rel=\"previous\"" if collection.previous_page
    links << "<#{url_for(params.merge(page: collection.next_page))}>; rel=\"next\"" if collection.next_page
    response.headers["Link"] = links.join(", ") if links.present?
    response.headers["X-Total-Count"] = collection.total_entries if collection.total_entries
    response.headers
  end

  # Protected: Devise parameters settings.
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:email, :password, :password_confirmation, :current_password, :name, :zone) }
  end

  # Protected: Sets the Time Zone for current User.
  def set_time_zone(&block)
    Time.use_zone(signed_in? && current_user.zone || Omakase::Application.config.time_zone, &block)
  end

  # Protected: Renders standard error page.
  def render_status(status, payload={})
    status_code, file = nil, nil
    case status
    when 400, :bad_request
      status_code, file, payload[:error] = 400, "public/400", I18n.t("errors.bad_request")
    when 401, :unauthorized
      status_code, file, payload[:error] = 401, "public/401", I18n.t("errors.unauthorized")
    when 403, :forbidden
      status_code, file, payload[:error] = 403, "public/403", I18n.t("errors.forbidden")
    when 404, :not_found
      status_code, file, payload[:error] = 404, "public/404", I18n.t("errors.not_found")
    when 422, :unprocessable_entity
      status_code, file, payload[:error] = 422, "public/422", I18n.t("errors.unprocessable_entity")
    when 500, :internal_server_error
      status_code, file, payload[:error] = 500, "public/500", I18n.t("errors.internal_server_error")
    end
    respond_to do |format|
      format.html   {render file: file, status: status_code, formats: [:html], layout: false}
      format.json   {render json: payload.reverse_merge(status_code: status_code), status: status_code}
      format.all    {render nothing: true, status: status_code}
    end if status_code and file
    true
  end

  # https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in
  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] || stored_location_for(resource) || root_path
  end

  def ssl_configured?
    Rails.env.production?
  end

end
