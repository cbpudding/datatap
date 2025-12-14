require "date"

class Item
  attr_reader :color, :description, :favicon, :footer, :image, :source, :timestamp, :title, :url, :video

  def initialize(url:, source:, title:, color: nil, description: nil, favicon: nil, footer: nil, image: nil, timestamp: nil, video: nil)
    @color = color if color
    @description = description if description
    @favicon = favicon if favicon
    @footer = footer if footer
    @image = image if image
    @source = source
    @timestamp = timestamp || DateTime.now
    @title = title
    @url = url
    @video = video if video
  end
end

class Provider
  def poll
    return []
  end

  def to_state
    return {}
  end
end
