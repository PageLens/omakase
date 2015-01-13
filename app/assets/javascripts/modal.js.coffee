# Public: Shows a modal dialog.
#
# title - Title on the dialog (required).
# content - HTML content (required).
# label - Label for the dismiss button (optional).
#
# Returns jQuery Object for the modal dialog.
#
Omakase.modal = (title, content, opts) ->
  options =
    label: I18n.t('global.close')
    modal_selector: '#remote-modal'
    content_selector: '.modal-content'
    btn_class: 'btn btn-primary'

  options = $.extend options, opts
  $modal = $(options.modal_selector)

  html =  """
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">#{I18n.t('global.close')}</span></button>
            <h4 class="modal-title">#{title}</h4>
          </div>
          <div class="modal-body">
            #{content}
          </div>
          <div class="modal-footer">
            <button type="button" class="#{options.btn_class}" data-dismiss="modal">#{options.label}</button>
          </div>
          """
  $(options.content_selector, $modal).html(html)
  $modal.modal('show')
