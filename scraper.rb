# frozen_string_literal: true

require 'HTTParty'
require 'nokogiri'
require 'timeout'

class ScraperInfo
  attr_reader :doc
  def initialize(url)
    @url = url
    @response = HTTParty.get(url)
    @html = @response.body
    @doc = Nokogiri::HTML(@html)
  end

  def run
    data
  end

  private

  def img_search(words_in_title)
    image = doc.search("meta[property='og:image']").map { |n| n['content'] }
    image = doc.search("link[rel='img_src']").map { |n| n['href'] } if image.empty?
    if image.empty?
      image = doc.xpath('//img').select do |img|
        img.key?('src') && words_in_title.any? { |word| img['src'].include?(word) }
      end.map { |img| img['src'] }
    end
    image
  end

  def description_search
    description = doc.search("meta[name='description'], meta[property='og:description']").map { |n| n['content'] }
    description.reject! do |content|
      content == ''
    end
    description = description.empty? ? 'No Description' : description[0]
  end

  def price_search
    price = doc.search("meta[property='og:price:amount']").map { |n| n['content'] }
    if price.empty?
      price = doc.css('span:contains("$")') 
    end
    unless price.empty?
      price = price.map {|n| n.text.match(/\$\d+(?:[.,]\d+)?/).to_s}
    end
    price.first
  end

  def data
    title = doc.title.strip
    description = description_search
    words_in_title = title.split(' ')
    image = img_search(words_in_title)
    price = price_search

    { title: title, description: description, image_url: image.sample, price: price || "Could not retrieve." }
    
  end
end

def scrape(url)
  timeout_in_sec = 3
  begin
    Timeout.timeout(timeout_in_sec) do
      ScraperInfo.new(url).run
    end
  rescue Timeout::Error
    'Unable to retrieve information.'
  end
end
