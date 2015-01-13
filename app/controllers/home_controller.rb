class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_user!, only:[:bookmarklet_popup]

  def index
  end

  def bookmarklet
  end

  def bookmarklet_popup
    render layout: false
  end

  def bookmarklet_js
    redirect_to view_context.combined_javascript_url("bookmarklet/bookmarklet")
  end

  def tools
  end

  def status
    User.count
    render text: 'OK'
  end
end
