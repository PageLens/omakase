class BookmarkImportsController < ApplicationController
  force_ssl if: :ssl_configured?
  respond_to :html

  def new
    @bookmark_import = BookmarkImport.new
  end

  def create
    @bookmark_import = current_user.bookmark_imports.new(bookmark_import_params)
    flash[:notice] = I18n.t('bookmark_imports.create.notice') if @bookmark_import.save
    respond_with(@bookmark_import, location: root_path)
  end

private
  def bookmark_import_params
    params.require(:bookmark_import).permit(:bookmark_file)
  end
end
