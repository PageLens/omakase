require 'rails_helper'

RSpec.describe FoldersController, :type => :controller do
  let(:user) {create(:user)}
  let(:valid_attributes) {
    {'name' => 'Test'}
  }

  let(:invalid_attributes) {
    {'name' => '#'*2000}
  }

  before do
    sign_in user
  end

  describe "GET index" do
    it "assigns all folders as @folders" do
      folder = create(:folder, user: user)
      get :index
      expect(assigns(:folders)).to eq([folder])
    end
  end

  describe "GET new" do
    it "assigns a new Folder as @folder" do
      get :new, {}
      expect(assigns(:folder)).to be_a_new(Folder)
    end
  end

  describe "GET show" do
    it "redirects to folder_links_path" do
      folder = create(:folder, user: user)
      get :show, id: folder.to_param
      expect(response).to redirect_to folder_links_url(folder_id: folder.to_param)
    end
  end

  describe "GET edit" do
    it "assigns the requested folder as @folder" do
      folder = create(:folder, user: user)
      get :edit, {:id => folder.to_param}
      expect(assigns(:folder)).to eq(folder)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Folder" do
        expect {
          post :create, {:folder => valid_attributes}
        }.to change(Folder, :count).by(1)
      end

      it "assigns a newly created folder as @folder" do
        post :create, {:folder => valid_attributes}
        expect(assigns(:folder)).to be_a(Folder)
        expect(assigns(:folder)).to be_persisted
      end

      it "redirects to the created Folder" do
        post :create, {:folder => valid_attributes}
        expect(response).to redirect_to(folders_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved folder as @folder" do
        post :create, {:folder => invalid_attributes}
        expect(assigns(:folder)).to be_a_new(Folder)
      end

      it "re-renders the 'new' template" do
        post :create, {:folder => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT update" do
    let(:folder) {create(:folder, user: user)}

    describe "with valid params" do
      let(:new_attributes) {
        {'name' => 'New Name'}
      }

      it "updates the requested Folder" do
        put :update, {:id => folder.to_param, :folder => new_attributes}
        folder.reload
        expect(folder.name).to eq 'New Name'
      end

      it "assigns the requested Folder as @folder" do
        put :update, {:id => folder.to_param, :folder => valid_attributes}
        expect(assigns(:folder)).to eq(folder)
      end

      it "redirects to the Folder" do
        put :update, {:id => folder.to_param, :folder => valid_attributes}
        expect(response).to redirect_to(folders_url)
      end
    end

    describe "with invalid params" do
      it "assigns the Folder as @folder" do
        put :update, {:id => folder.to_param, :folder => invalid_attributes}
        expect(assigns(:folder)).to eq(folder)
      end

      it "re-renders the 'edit' template" do
        put :update, {:id => folder.to_param, :folder => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested Folder if the current User is the creator of the Folder" do
      folder = create(:folder, user: user)
      expect {
        delete :destroy, {:id => folder.to_param}
      }.to change(Folder, :count).by(-1)
    end

    it "destroys the Sharing if the current User is not the creator of the Folder" do
      folder = create(:folder)
      sharing = create(:sharing, folder: folder, user: user)
      expect {
        expect {
          delete :destroy, {:id => folder.to_param}
        }.to change(Sharing, :count).by(-1)
      }.to_not change(Folder, :count)
    end

    it "redirects to the folder list" do
      folder = create(:folder, user: user)
      delete :destroy, {:id => folder.to_param}
      expect(response).to redirect_to(folders_url)
    end
  end

end
