class FoldersController < ApplicationController
  force_ssl if: :ssl_configured?
  before_action :set_folder, only: [:edit, :update, :destroy]
  respond_to :js, :html

  def index
    @folders = Folder.for_user(current_user)
  end

  def show
    redirect_to folder_links_path(folder_id: params[:id])
  end

  def new
    @folder = Folder.new
  end

  def edit
  end

  def create
    @folder = Folder.create(folder_params.merge(user_id: current_user.id))
    respond_with(@folder, location: folders_path)
  end

  def update
    @folder.update(folder_params)
    respond_with(@folder, location: folders_path)
  end

  def destroy
    if @folder.user_id == current_user.id
      @folder.destroy
    else
      Sharing.destroy_all(folder_id: @folder.id, user_id: current_user.id)
    end
    respond_with(@folder, location: folders_path)
  end

private
  def set_folder
    @folder = Folder.for_user(current_user).find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name)
  end
end
