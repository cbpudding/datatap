require "date"
require "json"
require "net/http"

require "./provider.rb"

class NOAAProvider < Provider
  def initialize(state)
    @last = DateTime.rfc3339 state["last"]
  end

  def poll
    alerts = []
    url = URI("https://api.weather.gov/alerts/active?status=actual&message_type=alert&urgency=Immediate,Expected,Future&severity=Extreme&certainty=Observed,Likely")
    Net::HTTP.start(url.host, url.port, :use_ssl => true) do |http|
      req = Net::HTTP::Get.new url
      res = http.request req
      data = JSON.parse res.body
      data["features"].reverse.each do |feature|
        sent = DateTime.rfc3339(feature["properties"]["sent"])
        next unless sent > @last
        @last = sent
        alerts.push Item.new(
          url: feature["id"],
          source: "NOAA",
          title: feature["properties"]["headline"],
          description: feature["properties"]["description"],
          timestamp: sent
        )
      end
    end
    return alerts
  end

  def to_state
    return {"last" => @last.rfc3339}
  end
end
