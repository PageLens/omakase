# Public: Sets the flash message on the page.
#
# kind - The kind of the flash message, either 'notice' or 'alert' (required).
# message - Message in the flash.
# options - Options Hash (optional):
#           :target - jQuery selector or object where the flash message will prepend to (default: 'div.alert-container').
#
# Returns jQuery Object for the flash message.
#
Omakase.flash = (kind, message, options) ->
  settings =
    target: 'body div.alert-container'

  settings = $.extend settings, options

  if kind == 'alert'
    alertClass = 'alert-danger'
  else
    alertClass = 'alert-info'

  html =  """
          <div class="alert #{alertClass}" data-alert>
            <button type="button" class="close" data-dismiss="alert">
              <span aria-hidden="true">&times;</span>
            </button>
            #{message}
          </div>
          """
  $('div.alert', $(settings.target)).remove()
  $(html).prependTo $(settings.target)
