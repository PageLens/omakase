require 'rails_helper'

RSpec.describe RedirectsController, :type => :controller do
  let(:email_delivery) {create(:email_delivery)}

  describe "GET show" do
    it "should render 404 if params[:u] is not present" do
      get :show
      expect(response.response_code).to eq 404
    end

    it "redirects to params[:u]" do
      get :show, :u => root_path
      expect(response).to redirect_to root_path
    end

    it "redirects to image_path(params[:i])" do
      get :show, :i => "pagelens_logo_388x100.png"
      expect(response).to redirect_to controller.view_context.image_path("pagelens_logo_388x100.png")
    end

    it "sets the read_at for EmailDelivery if params[:mr] present" do
      get :show, :u => root_path, :mr => email_delivery.tracking_code
      email_delivery.reload
      expect(email_delivery.read_at).to be_present
    end

    it "sets the read_at and clicked_at for EmailDelivery if params[:mc] present" do
      get :show, :u => root_path, :mc => email_delivery.tracking_code
      email_delivery.reload
      expect(email_delivery.read_at).to be_present
      expect(email_delivery.clicked_at).to be_present
    end
  end
end
