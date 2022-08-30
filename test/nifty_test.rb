require 'minitest/autorun'
require 'rack/test'
require_relative '../app.rb'

ENV['RACK_ENV'] = 'test'

class NiftyTest < MiniTest::Test

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  def test_show_wishlist
    get '/wishlist'
    assert_equal 200, last_response.status 
    assert_includes last_response.body, "<form method='post' action='/wishlist/new'>"
  end

end
