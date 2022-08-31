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
    originalurl = URI.parse(@url)
    image = doc.search("meta[property='og:image']").map { |n| n['content'] }
    image = doc.search("link[rel='img_src']").map { |n| n['href'] } if image.empty?
    if image.empty?
      image = doc.xpath('//img').select do |img|
        img.key?('src') && words_in_title.any? { |word| img['src'].include?(word) }
      end.map { |img| img['src'] }
    end

    image.map do |img|
      parsed_img = URI.parse(img)
      if parsed_img.host
        img
      else
        "#{originalurl.scheme}://#{originalurl.host}#{img}"
      end
    end
    # p uri.host
    # image
  end

  def description_search
    description = doc.search("meta[name='description'], meta[property='og:description']").map { |n| n['content'] }
    description.reject! do |content|
      content == ''
    end
    description.empty? ? 'No Description' : description[0]
  end

  def price_search
    price = doc.search("meta[property='og:price:amount']").map { |n| n['content'] }
    price = doc.css('span:contains("$")') if price.empty?
    price = doc.css('*:contains("$")') if price.empty?
    unless price.empty?
      price = price.map do |n|
        n = n.text unless n.is_a? String
        n.match(/\$?\d+(?:[.,]\d+)?/).to_s
      end
    end
    price.find { |pr| pr != '' && !pr.nil? }
  end

  def data
    title = doc.title.strip
    description = description_search
    words_in_title = title.split(' ')
    image = img_search(words_in_title)
    price = price_search

    { title: title, description: description, image_url: image.sample, price: price || '' }
  end
end

def scrape(url)
  timeout_in_sec = 3
  begin
    Timeout.timeout(timeout_in_sec) do
      ScraperInfo.new(url).run
    end
  rescue Timeout::Error
    :timeout_error
  end
end

p scrape('https://www.mec.ca/en/product/6009-278/airgrid-hike-short-sleeve-shirt?colour=Sea+Fog')
