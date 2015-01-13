require 'rails_helper'

RSpec.describe SettingsController, :type => :controller do
  let(:user) {create(:user, password: 'password', password_confirmation: 'password')}

  before do
    sign_in user
  end

  describe "GET edit" do
    it "assigns the current user as @user" do
      get :edit
      expect(assigns(:user)).to eq user
    end
  end

  describe "PUT update" do
    let(:valid_attributes) {
      {'name' => 'Test'}
    }

    it 'updates the user information' do
      put :update, {:id => user.id, :user => valid_attributes}
      user.reload
      expect(user.name).to eq 'Test'
      expect(response).to redirect_to root_url
    end

    it 'require current_password to update password' do
      put :update, {:id => user.id, :user => valid_attributes.merge(current_password: 'password', password: 'password1', password_confirmation: 'password1')}
      expect(response).to redirect_to root_url
      put :update, {:id => user.id, :user => valid_attributes.merge(password: 'password1', password_confirmation: 'password1')}
      expect(assigns(:user).errors).to be_present
    end

    it 'does not require current_password to update password if User does not have password' do
      user.update(encrypted_password: nil)
      sign_in user
      put :update, {:id => user.id, :user => valid_attributes.merge(password: 'password', password_confirmation: 'password')}
      expect(response).to redirect_to root_url
    end

  end

end
