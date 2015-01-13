require 'rails_helper'

RSpec.describe ClicksController, :type => :controller do
  let(:user) {create(:user)}
  let(:link) {create(:link, user: user)}

  describe 'POST create' do
    it 'assigns Link as @link' do
      post :create, link_id: link.id
      expect(assigns(:link)).to eq link
    end

    it 'creates a Click' do
      expect{post :create, link_id: link.id}.to change(Click, :count).by(1)
      expect(assigns(:click)).to be_a(Click)
      expect(assigns(:click).clicked_at).to be
    end

    it 'stores the User if the User is signed in' do
      post :create, link_id: link.id
      expect(assigns(:click).user).to be_nil
    end

    it 'does not store the User if the User is not signed in' do
      sign_in user
      post :create, link_id: link.id
      expect(assigns(:click).user).to eq user
    end

    it 'redirects to the URL of the Link' do
      post :create, link_id: link.id
      expect(response).to redirect_to link.url
    end
  end
end
