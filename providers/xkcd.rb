require "date"
require "json"
require "net/http"

require "./provider.rb"

class XkcdProvider < Provider
  def initialize(state)
    @last = state["last"]
  end

  def poll
    comic = []
    latest = URI("https://xkcd.com/info.0.json")
    Net::HTTP.start(latest.host, latest.port, :use_ssl => true) do |http|
      req = Net::HTTP::Get.new latest
      res = http.request req
      data = JSON.parse res.body
      if data["num"] > @last then
        comic.push Item.new(
          url: "https://xkcd.com/#{data["num"]}/",
          source: "xkcd",
          title: data["title"],
          favicon: "https://xkcd.com/s/919f27.ico",
          footer: data["alt"],
          image: data["img"],
          timestamp: DateTime.new(data["year"].to_i, data["month"].to_i, data["day"].to_i)
        )
        @last = data["num"]
      end
    end
    return comic
  end

  def to_state
    return {"last" => @last}
  end
end
