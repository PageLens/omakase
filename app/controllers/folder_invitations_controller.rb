class FolderInvitationsController < ApplicationController
  force_ssl if: :ssl_configured?
  before_action :set_folder_invitation, only: [:show, :update]
  respond_to :js, :html

  def show
  end

  def new
    @folder_invitation = FolderInvitation.new(folder_id: params[:folder_id])
  end

  def create
    @folder_invitation = FolderInvitation.create(folder_invitation_params.merge(user: current_user))
    respond_with(@folder_invitation)
  end

  def update
    @folder_invitation.accept_by!(current_user)
    respond_with(@folder_invitation, location: folder_links_path(@folder_invitation.folder_id))
  end

private
  def set_folder_invitation
    @folder_invitation = FolderInvitation.where(code: params[:id]).first!
  end

  def folder_invitation_params
    params.require(:folder_invitation).permit(:email, :message, :folder_id)
  end
end
