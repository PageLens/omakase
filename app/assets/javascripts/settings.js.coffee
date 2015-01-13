# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
ready = ->
  # settings#edit
  if $('body.settings.edit').length
    $('#user_password').on('input', ->
      if $(this).val().length
        $('div.password-present-group').removeClass('hide')
      else
        $('div.password-present-group').addClass('hide')
    )

$(document).ready(ready)
$(document).on("page:load load", ready)
