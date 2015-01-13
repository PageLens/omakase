module Api
  module V1
    class LinksController < ApplicationController
      force_ssl if: :ssl_configured?
      before_action :set_link, only: [:show, :update, :destroy]
      respond_to :json

      # GET /links.json
      def index
        @links = Link.paginate(page: params[:page], per_page: params[:per_page])
      end

      # GET /links/1.json
      def show
      end

      # POST /links.json
      def create
        @link = Link.new(link_params)
        if @link.save
          render :show, status: :created, location: @link
        else
          render json: @link.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /links/1.json
      def update
        if @link.update(link_params)
          render :show, status: :ok, location: @link
        else
          render json: @link.errors, status: :unprocessable_entity
        end
      end

      # DELETE /links/1.json
      def destroy
        @link.destroy
        head :no_content
      end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_link
        @link = Link.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def link_params
        params.require(:link).permit(:name, :keywords, :note, :source, :source_id, :source_uid, :saved_at, :saved_by, :user_id, :page_id)
      end
    end
  end
end
