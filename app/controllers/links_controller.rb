class LinksController < ApplicationController
  force_ssl if: :ssl_configured?, except: :bm_save
  skip_before_action :authenticate_user!, only: [:bm_save]
  before_action :set_link, only: [:show, :edit, :update, :destroy, :preview]
  before_action :set_folders
  after_action :allow_iframe, only: [:bm_save]
  respond_to :js, :html

  # GET /links
  def index
    # if not signed_in?
    #   logger.debug "User is not signed in"
    #   render 'home/index', layout: 'application'
    # else
      @links = Link.for_user(current_user, params).order('saved_at DESC').includes(:page).paginate(per_page: params[:per_page] || CONFIG[:link][:per_page], page: params[:page])
      render layout: false
    # end
  end

  # GET /links/search
  def search
    @search_response = Link.search_for_user(current_user, params).per_page(params[:per_page] || CONFIG[:link][:per_page]).page(params[:page])
    render layout: false
  end

  # GET /links/1
  def show
  end

  # GET /links/new
  def new
    @link = Link.new(folder_id: params[:folder_id])
  end

  # GET /links/1/edit
  def edit
  end

  # POST /links
  def create
    @link = Link.new(link_params.merge(source: Link::SOURCES[:web], user_id: current_user.id))
    @link.save
    respond_with(@link)
  end

  # PATCH/PUT /links/1
  def update
    @link.update(link_params)
    respond_with(@link)
  end

  # DELETE /links/1
  def destroy
    @link.destroy
    respond_with(@link)
  end

  def preview
  end

  def bm_save
    begin
      @link = LinkCreator.new.perform(
        url: params[:url],
        name: params[:name],
        note: params[:note],
        image_url: params[:image_url],
        description: params[:description],
        tags: params[:tags],
        source: params[:source] || Link::SOURCES[:web],
        user_id: current_user.id,
        saved_by: :me) if user_signed_in?
    rescue ActiveRecord::RecordInvalid => e
    end
    render layout: false
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_link
    @link = Link.for_user(current_user).find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def link_params
    params.require(:link).permit(:name, :keywords, :note, :url, :folder_id, :tags)
  end

  def set_folders
    if signed_in?
      @folders = Folder.for_user(current_user)
      @folder = @folders.detect {|f| f.id.to_s == params[:folder_id]} if params[:folder_id].present?
    end
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

end
