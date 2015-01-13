require 'rails_helper'

RSpec.describe FolderInvitationsController, :type => :controller do
  let(:user) {create(:user)}
  let(:folder) {create(:folder, user: user)}
  let(:valid_attributes) {
    {'email' => 'test@example.com', 'message' => 'Try me', 'folder_id' => folder.id}
  }

  let(:invalid_attributes) {
    {'email' => ''}
  }

  before do
    sign_in user
  end

  describe "GET new" do
    it "assigns a new FolderInvitation as @folder_invitation" do
      get :new, {}
      expect(assigns(:folder_invitation)).to be_a_new(FolderInvitation)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new FolderInvitation" do
        expect {
          post :create, {:folder_invitation => valid_attributes}
        }.to change(FolderInvitation, :count).by(1)
      end

      it "assigns a newly created FolderInvitation as @folder_invitation" do
        post :create, {:folder_invitation => valid_attributes}
        expect(assigns(:folder_invitation)).to be_a(FolderInvitation)
        expect(assigns(:folder_invitation)).to be_persisted
      end

      it "redirects to the created FolderInvitation" do
        post :create, {:folder_invitation => valid_attributes}
        expect(response).to redirect_to(folder_invitation_url(assigns(:folder_invitation)))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved FolderInvitation as @folder_invitation" do
        post :create, {:folder_invitation => invalid_attributes}
        expect(assigns(:folder_invitation)).to be_a_new(FolderInvitation)
      end

      it "re-renders the 'new' template" do
        post :create, {:folder_invitation => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT update" do
    let(:folder_invitation) {create(:folder_invitation)}

    it "updates the requested FolderInvitation" do
      put :update, {:id => folder_invitation.to_param}
      folder_invitation.reload
      expect(folder_invitation.status).to eq 'accepted'
    end

    it "assigns the requested FolderInvitation as @folder_invitation" do
      put :update, {:id => folder_invitation.to_param}
      expect(assigns(:folder_invitation)).to eq(folder_invitation)
    end

    it "redirects to the Folder" do
      put :update, {:id => folder_invitation.to_param}
      expect(response).to redirect_to(folder_links_url(folder_invitation.folder_id))
    end
  end
end
