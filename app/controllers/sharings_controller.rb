class SharingsController < ApplicationController
  before_action :set_folder, only: [:destroy]
  respond_to :js

  def index
    @folder = Folder.for_user(current_user).includes(sharings: [:user]).find(params[:folder_id])
    @sharings = @folder.sharings
  end

  def destroy
    @sharing = @folder.sharings.find(params[:id])
    @sharing.destroy
  end

private
  def set_folder
    @folder = Folder.for_user(current_user).find(params[:folder_id])
  end
end
