require "date"
require "json"
require "net/http"

require "./provider.rb"
require "./utility.rb"

class SteamProvider < Provider
  def initialize(state)
    @games = state
  end

  def poll
    items = []
    # https://developer.valvesoftware.com/wiki/Steam_Web_API#GetNewsForApp_.28v0001.29
    url = URI("https://api.steampowered.com/ISteamNews/GetNewsForApp/v0002")
    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      @games.each do |game|
        url = URI("https://api.steampowered.com/ISteamNews/GetNewsForApp/v0002/?appid=#{game["id"]}&format=json")
        req = Net::HTTP::Get.new url
        res = http.request req
        news = JSON.parse res.body
        news["appnews"]["newsitems"].reverse.each do |item|
          next unless item["date"] > game["last"]
          game["last"] = item["date"]
          # TODO: Parse BBCode from Steam into Markdown ~ahill
          contents = item["contents"].gsub(%r{\[/?[^\]]+?\]}, "")
          contents = contents.gsub(%r{\n{3,}}, "\n\n")
          meta = scrape_html item["url"]
          items.push Item.new(
            color: meta[:color],
            description: contents,
            image: meta[:image],
            source: "#{item["author"]} via Steam",
            timestamp: DateTime.strptime(item["date"].to_s, "%s"),
            title: item["title"],
            url: item["url"]
          )
        end
      end
    end
    return items
  end

  def to_state
    return @games
  end
end
