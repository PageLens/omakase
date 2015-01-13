# srcwidth/srcheight are the dimensions of the orignal image
# targetwidth and targetheight are the dimensions of the rendering area
# fLetterBox implies "add black bars" if true.  If false, the image is "zoomed" (cropped on one dimension) such that it fills the ene target space
# The result object returned has the following properties:
#     width: width to scale the image to
#     height: height to scale the image to
#     targetleft: position relative to the left edge of the target to center the image (can be negative when fLetterBox is false)
#     targettop: position relative to the top edge of the target to center the image (can be negative when fLetterBox is false)
scaleImage = (srcwidth, srcheight, targetwidth, targetheight, fLetterBox) ->
  result = { width: 0, height: 0, fScaleToTargetWidth: false }
  if (srcwidth <= 0) || (srcheight <= 0) || (targetwidth <= 0) || (targetheight <= 0)
    return result

  # scale to the target width
  scaleX1 = targetwidth
  scaleY1 = (srcheight * targetwidth) / srcwidth

  # scale to the target height
  scaleX2 = (srcwidth * targetheight) / srcheight
  scaleY2 = targetheight

  # now figure out which one we should use
  fScaleOnWidth = (scaleX2 > targetwidth)
  if fScaleOnWidth
    fScaleOnWidth = fLetterBox;
  else
    fScaleOnWidth = !fLetterBox

  if (fScaleOnWidth)
    result.width = Math.floor(scaleX1)
    result.height = Math.floor(scaleY1)
    result.fScaleToTargetWidth = true
  else
    result.width = Math.floor(scaleX2)
    result.height = Math.floor(scaleY2)
    result.fScaleToTargetWidth = false

  result.targetleft = Math.floor((targetwidth - result.width) / 2)
  result.targettop = Math.floor((targetheight - result.height) / 2)

  result

cropImage = (div, img) ->
  rememberOriginalSize(img)
  targetwidth = $(div).width()
  targetheight = $(div).height()
  srcwidth = img.originalsize.width
  srcheight = img.originalsize.height
  result = scaleImage(srcwidth, srcheight, targetwidth, targetheight, false)
  img.width = result.width
  img.height = result.height
  $(img).css("top", result.targettop).css("left", result.targetleft)

window.cropContainerImage = (div, container=document) ->
  div = $(div, container)[0]
  img = $('img', div)[0]
  $(img).on('load', ->
    cropImage(div, img)
  )

rememberOriginalSize = (img) ->
  if !img.originalsize
    img.originalsize = {width: img.width, height: img.height}

ready = ->
  $('#remote-modal').
  on('hidden.bs.modal', ->
    $('.modal-content', this).html('')
  ).
  on('shown.bs.modal', ->
    $('#remote-modal [autofocus]:first').focus();
  )

$(document).ready(ready)
$(document).on("page:load load", ready)
