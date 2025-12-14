require "date"
require "json"
require "net/http"

require "./provider.rb"

class JMAProvider < Provider
  def initialize(state)
    @last = DateTime.rfc3339(state["last"])
  end

  def poll
    alerts = []
    list = URI("https://www.jma.go.jp/bosai/quake/data/list.json")
    Net::HTTP.start(list.host, list.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new list
      res = http.request req
      data = JSON.parse res.body
      data.reverse.each do |summary|
        max_intensity = summary["maxi"].to_i || 1
        next unless max_intensity >= 3
        timestamp = DateTime.rfc3339(summary["at"])
        next unless timestamp > @last
        @last = timestamp
        details_url = URI("https://www.jma.go.jp/bosai/quake/data/#{summary["json"]}")
        req = Net::HTTP::Get.new details_url
        res = http.request req
        details = JSON.parse res.body
        description = <<~HEREDOC
        #{details["Head"]["enTitle"].strip}

        Forecast: #{details["Body"]["Comments"]["ForecastComment"]["enText"].strip}
        HEREDOC
        description += "\nLocation: #{details["Body"]["Earthquake"]["Hypocenter"]["Area"]["enName"].strip}" if details["Body"]["Earthquake"]
        description += "\nMagnitude: #{details["Body"]["Earthquake"]["Magnitude"].strip}" if details["Body"]["Earthquake"]
        alerts.push Item.new(
          description: description,
          source: "JMA",
          timestamp: timestamp,
          title: details["Head"]["Headline"]["Text"],
          url: "https://www.data.jma.go.jp/multi/quake/quake_detail.html?eventID=#{summary["ctt"]}&lang=en"
        )
      end
    end
    return alerts
  end

  def to_state
    return {"last" => @last.rfc3339}
  end
end
