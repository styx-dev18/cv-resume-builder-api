module ApplicationHelper
  def external_href(url)
    url =~ %r{\Ahttps?://}i ? url : "https://#{url}"
  end
end
