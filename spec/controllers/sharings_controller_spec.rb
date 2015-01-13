require 'rails_helper'

RSpec.describe SharingsController, :type => :controller do
  let(:user) {create(:user)}
  let(:folder) {create(:folder, user: user)}
  let(:sharing) {create(:sharing, folder: folder, creator: user)}

  before do
    sign_in user
  end

  describe "GET index" do
    it "assigns sharings as @sharings" do
      sharing
      xhr :get, :index, folder_id: folder.to_param
      expect(assigns(:sharings)).to eq([sharing])
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested Sharing" do
      sharing
      expect {
        xhr :delete, :destroy, id: sharing.to_param, folder_id: folder.to_param, format: :js
      }.to change(Sharing, :count).by(-1)
    end
  end
end
