# Public: Shows a modal message dialog in replacement of JavaScript alert.
#
# title - Title on the dialog (required).
# message - Message on the dialog (required).
# label - Label for the dismiss button (optional).
#
# Returns jQuery Object for the modal dialog.
#
Omakase.alert = (title, message, label) ->
  Omakase.modal(title, _.escape(message), { label: label })
