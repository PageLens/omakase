# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
Omakase.Folders = Omakase.Folders || {}
Omakase.Folders.insertToSidebar = (html) ->
  $item = $(html);
  inserted = false;
  $('ul.folders-sidebar .folder-item').each( ->
    if $(this).data('name') > $item.data('name')
      $item.insertBefore(this) if (!inserted)
      inserted = true
  )
  unless inserted
    $item.insertBefore('ul.folders-sidebar #new-folder-link')

  $item.trigger('folder-added')
