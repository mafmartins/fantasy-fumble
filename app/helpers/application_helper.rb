module ApplicationHelper
  def active_page(og_name, controller_page_name)
    "active" if og_name.downcase.eql?(controller_page_name.downcase)
  end
end
