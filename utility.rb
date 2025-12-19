require "net/http"
require "nokogiri"

def scrape_html(uri)
  meta = {}
  location = uri
  res = nil
  begin
    url = URI(location)
    return meta if url.scheme != "https"
    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new url
      res = http.request req
      location = res["location"]
    end
  end while res.is_a?(Net::HTTPRedirection)
  dom = Nokogiri::HTML(res.body)
  color = dom.css("[name=theme-color]").first
  meta[:color] = color["content"][1..].to_i(16) if color
  image = dom.css("[property='og:image']").first
  meta[:image] = image["content"] if image
  return meta
end
