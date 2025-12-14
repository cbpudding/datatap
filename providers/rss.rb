require "date"
require "net/http"
require "rss"

require "./provider.rb"
require "./utility.rb"

class RSSProvider < Provider
  def initialize(state)
    @feeds = []
    state.each do |feed|
      last = DateTime.rfc2822(feed["last"]) if feed["last"]
      @feeds.push({
        "last" => last || DateTime.now,
        "url" => feed["url"]
      })
    end
  end

  def poll
    items = []
    @feeds.each do |feed|
      rss = RSS::Parser.parse(feed["url"])
      rss.items.reverse.each do |item|
        pubDate = DateTime.parse(item.pubDate.to_s)
        next unless pubDate > feed["last"]
        feed["last"] = pubDate
        description = item.description.gsub(%r{</?[^>]+?>}, "")
        description = description.gsub(%r{\n{3,}}, "\n\n")
        meta = scrape_html(item.link)
        items.push Item.new(
          color: meta[:color],
          description: description,
          image: meta[:image],
          source: rss.channel.title,
          timestamp: pubDate,
          title: item.title,
          url: item.link
        )
      end
    end
    return items
  end

  def to_state
    feeds = []
    @feeds.each do |feed|
      feeds.push({
        "last" => feed["last"].rfc2822,
        "url" => feed["url"]
      })
    end
    return feeds
  end
end
