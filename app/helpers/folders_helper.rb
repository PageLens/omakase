module FoldersHelper
  def modal_form_title(folder)
    if folder.persisted?
      folder.name
    else
      t('folders.modal_form.new_folder')
    end
  end
end
