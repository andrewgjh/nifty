# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'erubis'
require 'yaml'
require 'uuid'
require 'time'

require_relative 'scraper.rb'

WISHLIST = YAML.load_file('wishlist.yml')

def db_save
  File.open('wishlist.yml', 'w') do |file|
    YAML.dump(WISHLIST, file)
  end
end

def validate(input)
  if input.strip.empty?
    session[:error] = 'Please provide a valid wishlist item.'
    redirect '/wishlist'
  end
end

def url?(input)
  a_url = input =~ /\A#{URI::DEFAULT_PARSER.make_regexp}\z/
  !!a_url
end

def create(item, time_submitted)
  if url?(item)
    data = scrape(item)
  else
    data = { title: item }
  end
  data[:time_submitted] = time_submitted
  WISHLIST[UUID.new.generate] ||= data
end

configure do
  enable :sessions
  set :session_secret, 'secret_key'
end

helpers do
  def the_time
    t = Time.new
    t.strftime('%FT%R')
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def hattr(text)
    Rack::Utils.escape_path(text)
  end
end

get '/' do
  redirect '/wishlist'
end

get '/wishlist' do
  erb :wishlist
end

delete '/wishlist/:id' do |id|
  WISHLIST.delete(id)
  db_save
  status 204
end

post '/wishlist/new' do
  entry = params[:wishlist_item]
  create(entry, params[:time_submitted])
  db_save
  session[:message] = 'The item was successfully added!'
  redirect '/wishlist'
end

get '/wishlist/:item' do |item|
  @item = WISHLIST[item]
  erb :wishlist_item
end
