module ApplicationHelper
  def pagination_for(collection)
    content_tag(:div, will_paginate(collection, next_label: t('global.next'), previous_label: t('global.previous'), inner_window: 1, renderer: BootstrapPagination::Rails), class: 'text-center')
  end

  # Public: Returns time tag for the time in a human friendly format.
  #
  # time - Time or String for the time.
  # options - Hash options used to refine the content (defaults: {}).
  #           :long_format_distance - If the time is before this, it uses long format (default: 1.month).
  #
  # Returns HTML Time tag.
  def friendly_time_tag(time, options={})
    return nil if time.nil?
    options = options.reverse_merge(:long_format_distance => 1.month)
    from_time = time.to_time if time.respond_to?(:to_time)
    from_time = Time.zone.parse(time) if time.is_a? String
    distance_in_minutes = (((Time.now - from_time).abs) / 60).round
    content = case distance_in_minutes
    when 0..(options[:long_format_distance] / 60 - 1)
      I18n.t('global.time_ago', :time => distance_of_time_in_words_to_now(from_time))
    else
      I18n.l(from_time.to_date, :format => :long)
    end
    content_tag(:time, content, :datetime => from_time.utc.iso8601)
  end
end
