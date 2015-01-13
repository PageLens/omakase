# Provides I18n for HandlerBars Template.
# Examples:
#   {{t "global.display_name" given_name="Jerry" surname="Luk" title=title }}
#   {{t "global.back" }}
Handlebars.registerHelper 't', (key, options) ->
  new Handlebars.SafeString(I18n.t(key, options.hash))
