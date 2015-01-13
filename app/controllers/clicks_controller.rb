class ClicksController < ApplicationController
  force_ssl if: :ssl_configured?
  skip_before_action :authenticate_user!

  def create
    @link = Link.includes(:page).find(params[:link_id])
    @click = Click.create(user: current_user, link: @link)
    redirect_to @link.url
  end
end
