class HomeController < ApplicationController
  allow_unauthenticated_access
  def index
    @page_name = "home"
    @page_title = "About Fantasy Fumble"
  end
end
