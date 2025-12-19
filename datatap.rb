require "json"
require "net/http"
require "yaml"

require "./providers/jma.rb"
require "./providers/noaa.rb"
require "./providers/rss.rb"
require "./providers/steam.rb"
require "./providers/xkcd.rb"

def publish(items)
  webhook = URI($state["discord"]["webhook"])
  # https://discord.com/developers/docs/resources/webhook#execute-webhook
  Net::HTTP.start(webhook.host, webhook.port, :use_ssl => true) do |http|
    req = Net::HTTP::Post.new webhook
    req.content_type = "application/json"
    items.each do |item|
      # https://discord.com/developers/docs/resources/message#embed-object
      message = {
        embeds: [{
          provider: {
            name: item.source
          },
          timestamp: item.timestamp.iso8601,
          title: item.title,
          url: item.url
        }],
        thread_name: item.title,
        username: item.source
      }
      message[:thread_name] = "#{message[:thread_name][..96]}..." if message[:thread_name].length > 100
      if item.description then
        # NOTE: Discord counts \n as TWO characters instead of one. We'll adjust
        #       the description character limit accordingly. ~ahill
        limit = 4096 - item.description.count("\n")
        description = item.description[..limit]
        description = "#{description[..(limit - 3)]}..." if item.description.length > limit
        message[:embeds][0][:description] = description
      end
      message[:avatar_url] = item.favicon if item.favicon
      message[:embeds][0][:color] = item.color if item.color
      message[:embeds][0][:footer] = {text: item.footer} if item.footer
      message[:embeds][0][:image] = {url: item.image} if item.image
      message[:embeds][0][:video] = {url: item.video} if item.video
      req.body = JSON.generate message
      res = http.request req
      if res.code[0] != "2" then
        puts "#{res.inspect}: #{message.inspect}"
      end
    end
  end
end

$state = YAML.load(File.read("state.yml"))

providers = {
  "jma" => JMAProvider.new($state["jma"]),
  "noaa" => NOAAProvider.new($state["noaa"]),
  "rss" => RSSProvider.new($state["rss"]),
  "steam" => SteamProvider.new($state["steam"]),
  "xkcd" => XkcdProvider.new($state["xkcd"])
}

loop do
  items = []

  providers.each do |name, provider|
    begin
      items.push *(provider.poll)
    rescue => e
      puts "#{e}"
    end
  end

  publish items unless items.empty?

  providers.each do |name, provider|
    $state[name] = provider.to_state
  end

  File.write "state.yml", YAML.dump($state)

  sleep 300
end
