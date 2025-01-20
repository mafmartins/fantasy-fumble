module ApplicationHelper
  def active_page(og_name, controller_page_name)
    if controller_page_name.present?
      "active" if og_name.downcase.eql?(controller_page_name.downcase)
    else
      ""
    end
  end
end
