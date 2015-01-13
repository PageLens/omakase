require 'action_view/helpers/translation_helper'
module TranslationHelper
  include ActionView::Helpers::TranslationHelper

  @@markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true)

  def translate_with_markdown(key, options={})
    if markdown_translation_key?(key)
      @@markdown.render(translate_without_markdown(key, options)).html_safe
    else
      translate_without_markdown(key, options)
    end
  end
  alias_method_chain :translate, :markdown
  alias :t :translate

private
  def markdown_translation_key?(key)
    key.to_s =~ /(\b|_|\.)markdown$/
  end

  def html_safe_translation_key?(key)
    markdown_translation_key?(key) or key.to_s =~ /(\b|_|\.)html$/
  end
end
