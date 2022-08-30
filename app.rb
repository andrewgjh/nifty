require 'sinatra'
require 'sinatra/reloader'
require 'erubis'
require 'yaml'
require 'uuid'

WISHLIST = YAML.load_file('wishlist.yml')

def db_save
  File.open('wishlist.yml', 'w') do |file|
    YAML.dump(WISHLIST, file)
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
  WISHLIST[UUID.new.generate] ||= params[:wishlist_item]
  db_save
  redirect '/wishlist'
end

get '/wishlist/:item' do |item|

end

