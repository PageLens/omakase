require 'rails_helper'

RSpec.describe BookmarkImportsController, :type => :controller do
  let(:user) {create(:user)}
  let(:bookmark_file) {fixture_file_upload('/bookmark_file.html', 'text/html')}
  let(:bookmark_import) {create(:bookmark_import, user: user, bookmark_file: bookmark_file)}
  let(:valid_attributes) {
    {'bookmark_file' => bookmark_file}
  }

  let(:invalid_attributes) {
    {'some' => 'bogus'}
  }

  before do
    sign_in user
  end

  describe "GET new" do
    it "assigns a new BookmarkImport as @bookmark_import" do
      get :new, {}
      expect(assigns(:bookmark_import)).to be_a_new(BookmarkImport)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new BookmarkImport" do
        expect {
          post :create, {:bookmark_import => valid_attributes}
        }.to change(BookmarkImport, :count).by(1)
      end

      it "assigns a newly created BookmarkImport as @bookmark_import" do
        post :create, {:bookmark_import => valid_attributes}
        expect(assigns(:bookmark_import)).to be_a(BookmarkImport)
        expect(assigns(:bookmark_import)).to be_persisted
      end

      it "redirects to the links path" do
        post :create, {:bookmark_import => valid_attributes}
        expect(response).to redirect_to(root_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved BookmarkImport as @bookmark_import" do
        post :create, {:bookmark_import => invalid_attributes}
        expect(assigns(:bookmark_import)).to be_a_new(BookmarkImport)
      end

      it "re-renders the 'new' template" do
        post :create, {:bookmark_import => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end
end
