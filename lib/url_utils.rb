class UrlUtils
  def self.append_protocol(url, protocol='http')
    if url.present? and url !~ /^(http|https):\/\//
      "#{protocol}://#{url.downcase}"
    else
      url
    end
  end
end
