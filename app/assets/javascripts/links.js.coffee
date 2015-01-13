Omakase.Links = Omakase.Links || {}
Omakase.Links.addToContainer = (html, container='ul.links') ->
  $item = $(html)
  $container = $(container)
  $existing_item = $("#link-#{$item.data('id')}")

  if $existing_item.length
    if $container.data('folder-id')? && $container.data('folder-id') != $item.data('folder-id')
      $existing_item.remove()
    else
      $existing_item.replaceWith($item)
  else
    $item.prependTo($container)

  $item.trigger('link-added')

ready = ->
  # links#index
  if $('body.links.index').length or $('body.links.search').length
    $(document).on('folder-added', (event) ->
      $folder_item = $(event.target)
      $folder_item.droppable(
        accept: '.drag-to-folder',
        hoverClass: 'bg-primary',
        drop: (event, ui) ->
          $link_item = ui.draggable.parents('.link-item')
          $.ajax(
            url: Routes.link_path($link_item.data('id')),
            method: 'patch',
            data:{link: {folder_id: $folder_item.data('id') || ''}}
          )
      )
    ).on('link-added', (event) ->
      $link_item = $(event.target)
      cropContainerImage('div[data-crop-image=fit].image-container', $link_item);
      $('.drag-to-folder', $link_item).draggable(
        helper: 'clone',
        zIndex: 10000,
        start: ->
          $('ul.folders-sidebar').addClass('bg-warning')
        stop: ->
          $('ul.folders-sidebar').removeClass('bg-warning')
      )
    )

    $('ul.folders-sidebar .folder-item').trigger('folder-added')
    $('ul.links .link-item').trigger('link-added')

  #links#bm_save
  if $('body.links.bm_save').length
    bm_url = null

    # Sends message from inside the iframe to the parent which has LinkCreator injected
    postMessageToLinkCreator = (data) ->
      top.postMessage(JSON.stringify(data), bm_url)

    close = ->
      $('div.alert').slideUp(400, ->
        postMessageToLinkCreator(close: true))

    $('button.close').on('click', ->
      close()
    )

    $('a.popup').on('click', (e) ->
      e.preventDefault()
      $target = $(e.target)
      window.open($target.attr('href'),
        'pl_popup',
        'location=yes,links=no,scrollbars=no,toolbar=no,width=480,height=600')
    )

    $('div[data-close]').each(->
      setTimeout(close, $(this).data('close'));
    )

    $(window).on('message', (e) ->
      data = $.parseJSON(e.originalEvent.data);
      if (data.iframe_loaded)
        bm_url = data.iframe_loaded.page_url
        postMessageToLinkCreator(dimension: { width: $(document).width(), height: $(document).height() })
    )

$(document).ready(ready)
$(document).on("page:load load", ready)
