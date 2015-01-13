class PageLens.LinkCreator
  $ = jQuery.noConflict(true)

  postMessageToIFrame = (data) ->
    iframe_window.postMessage(JSON.stringify(data), host)

  constructor: (options={}) ->
    hostname = window.PLhost || 'pagelen.com'
    create_path = options.create_path || 'links/bm_save'
    @host = if document.location.protocol == 'https:' then "https://#{hostname}" else "http://#{hostname}"
    @create_url = "#{@host}/#{create_path}"
    @version = window.PLv || 3
    @url = window.location.href
    @name = document.title

    if @version == 3
      $widget = @createWidget(@host)
      @bindMessage($widget)
      $widget.appendTo($('body'))

  createWidget: (host) ->
    $widget = $('<div></div>')
      .css(
        zIndex: 999999,
        position: 'fixed',
        top: '10px',
        right: 0,
        textAlign: 'right',
        backgroundColor: 'transparent'
      )

    $iframe = $('<iframe frameborder="0" allowTransparency="true"></iframe>')
      .attr('src', "#{@create_url}?#{$.param(
        url: @url,
        name: @name,
        v: @version
      )}")
      .width(0)
      .height(0)
      .bind('load', (e) =>
        iframe_window = e.originalEvent.target.contentWindow
        iframe_window.postMessage(JSON.stringify(
          iframe_loaded: { page_url: @url }
        ), @host)
      )

    $widget.append($iframe)

  bindMessage: ($widget) ->
    $(window).bind('message', (e) =>
      event = e.originalEvent
      if event.origin == @host
        data = $.parseJSON(event.data)
        if data.log then console.log data.log
        if data.close then $widget.remove()
        if data.dimension
          $('iframe', $widget).width(data.dimension.width).height(data.dimension.height)
    )

  # new LinkCreator()
