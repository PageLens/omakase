module HomeHelper
  def combined_javascript_url(package)
    path = javascript_include_tag(package, :debug => false).scan(/src="(.*)"/).flatten.first
    (path =~ /^http(s)?:\/\//) ? path : "//#{request.host_with_port}#{path}"
  end

  def browser
    browser = Browser.new(
      :ua => request.env['HTTP_USER_AGENT'],
      :accept_language => request.env['HTTP_ACCEPT_LANGUAGE'])
    if browser.safari?
      return :safari
    elsif browser.chrome?
      return :chrome
    elsif browser.firefox?
      return :firefox
    elsif browser.ie?
      return :ie
    else
      return :other
    end
  end
end
