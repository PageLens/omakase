# Extends Rails JavaScript to use modal dialog for confirm.
$.rails.allowAction = (element) ->
  message = element.data('confirm') || element.attr('confirm')
  title = element.data('confirm-title') || I18n.t('global.delete_confirmation_title')
  cancel = element.data('confirm-cancel') || I18n.t('global.cancel')
  ok = element.data('confirm-ok') || I18n.t('global.ok')
  btn_class = element.data('confirm-class') || 'btn-danger'
  # If there's no message, there's no data-confirm attribute,
  # which means there's nothing to confirm
  return true unless message
  $('#confirmModal').remove()
  # Clone the clicked element (probably a delete link) so we can use it in the dialog box.
  $link = element.clone()
    # We don't necessarily want the same styling as the original link/button.
    .removeAttr('class')
    # We don't want to pop up another confirmation (recursion)
    .removeAttr('data-confirm')
    # We want a button
    .addClass('btn').addClass(btn_class)
    # We want it to sound confirmy
    .html(ok)

  $modal = Omakase.modal(title, message, {label: cancel, btn_class: 'btn btn-default'})
  # Add the new button to the modal box
  $modal.find('.modal-footer').append($link)
  # Prevent the original link from working
  return false
