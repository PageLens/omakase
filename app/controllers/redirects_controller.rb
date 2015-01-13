class RedirectsController < ApplicationController
  skip_before_action :authenticate_user!

  # Redirects to URL specified in params[:u].
  # Redirects to Image specified in params[:i].
  # It updates EmailDelivery if it contains params[:mc] or params[:mr].
  #
  def show
    process_email_delivery_tracking(params)
    if params[:u].present?
      redirect_to params[:u]
    elsif params[:i].present?
      redirect_to view_context.image_path(params[:i])
    else
      render_status(:not_found)
    end
  end

private
  def process_email_delivery_tracking(params)
    # mc represents MailClicked, mr represents MailRead
    if params[:mc].present? or params[:mr].present?
      email_delivery = EmailDelivery.where(tracking_code: (params[:mr] || params[:mc])).first
      return unless email_delivery
      email_delivery.read_at ||= Time.now
      email_delivery.clicked_at ||= Time.now if params[:mc].present?
      email_delivery.save!
    end
  end
end
