# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require "sinatra/json"
require 'erubis'
require 'yaml'
require 'uuid'
require 'time'
require 'bcrypt'

require_relative 'scraper.rb'

require_relative 'firebase_db.rb'


FIREBASE = FirebaseService.new()


def validate(input)
  return unless input.strip.empty?

  session[:error] = 'Please provide a valid wishlist item.'
  redirect '/wishlist'
end

def url?(input)
  a_url = input =~ /\A#{URI::DEFAULT_PARSER.make_regexp}\z/
  !!a_url
end

def create(input, user_id, owner_email)
  if url?(input)
    payload = scrape(input)
    if payload == :timeout_error
      session[:error] = 'Unable to retrieve url information, please submit information manually.'
      return false
    end
    payload[:original_url] = input
    payload[:belongs_to] = user_id
    payload[:belongs_to_email] = owner_email
  else
    payload = { title: input, belongs_to: user_id , belongs_to_email: owner_email}
  end
  payload[:time_submitted] = Time.now.strftime("%b %d, %Y")
  FIREBASE.add_to_wishlist(payload, user_id)
end



def good?(password)
  session[:error] = 'The password needs to be minimum 5 characters long.' unless password.length >= 5
  password.length >= 5
end


def registered?(email)
  registered_user = db_has_user?(email)
  session[:error] = 'This user has not been registered.' unless registered_user
  registered_user
end


def validate_signup(email, password)
  unless FIREBASE.unique?(email)
    session[:error] = 'That email has already been registered in the system.'
    return false
  end
  return false unless good?(password)

  session[:message] = 'Welcome to Nifty'
  true
end

def validate_login(email, password)
  user_found = FIREBASE.get_user(email)
  matching_password = FIREBASE.pw_match?(email, password)
  session[:error] = 'This email is not registered in our database' unless user_found
  if user_found
    session[:error] = 'The password does not match our records.' unless matching_password
  end

  return false unless user_found && matching_password

  session[:message] = 'Welcome to Nifty'
  user_found
end

def generate_sess_token
  token = UUID.new.generate
  { token_id: token, time_created: Time.now }
end

def active_token?(user)
  expire_in_sec = 3600
  time_of_expire = Time.parse(user["session_id"]["time_created"]) + expire_in_sec
  p (time_of_expire > Time.now)
end

def current_user 
  return nil unless session[:token]
  
  FIREBASE.current_user(session[:token])
end

def valid_token?
  user = current_user
  user && active_token?(user)
end

def logged_in?
  session.key?(:token) && valid_token?
end

def loggedin_only
  return if logged_in?

  session[:error] = 'Please log in to assess this resource.'
  redirect '/login'
end

def search_for_user(possible_user)
  possible_user_arr = FIREBASE.find_user(possible_user)
end

def load_wishlist(usr_id)
  FIREBASE.load_wishlist(usr_id) || []
end



configure do
  enable :sessions
  set :session_secret, 'secret_key'
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def hattr(text)
    Rack::Utils.escape_path(text)
  end

end

get '/login' do
  if logged_in?
    session[:error] = "You are already logged in as #{session[:token][:email]}."
    redirect '/' 
  end
  erb :login
end


get '/signup' do
  if logged_in?
    session[:error] = "You are already logged in as #{session[:token][:email]}."
    redirect '/' 
  end
  erb :signup
end

post '/login' do
  email = params[:email]
  password = params[:password]
  user_found = validate_login(email, password)
  p ['fjkdlsjfds', user_found]
  redirect '/login' unless user_found

  session_token = generate_sess_token
  session_token[:email] = email
  
  FIREBASE.update_user_session(user_found["user_id"], {session_id: session_token})
  session[:token] = session_token
  
  redirect '/wishlist'
end

post '/signup' do
  email = params[:email]
  password = params[:password]
  redirect '/signup' unless validate_signup(email, password)

  session[:token] = FIREBASE.create_user(email, password)
  redirect '/wishlist'
end

get '/logout' do
  session.delete(:token)

  redirect '/'
end

get '/' do
  erb :home
end

get '/wishlist' do
  loggedin_only
  @user = FIREBASE.current_user(session[:token])
  
  @wishlist = load_wishlist(@user['user_id'])
  p ['wishlist', @wishlist]
  erb :wishlist
end

get '/wishlists/user/:user_id' do |user_id|
  @wishlist = load_wishlist(user_id)
  json @wishlist
end

get '/wishlist/search' do 
  possible_user = params[:email]
  
  json search_for_user(possible_user)
end

delete '/wishlist/:id' do |id|
  loggedin_only
  user = current_user
  FIREBASE.delete_item(user['user_id'], id)
  status 204
end

post '/wishlist/new' do
  loggedin_only
  user = current_user
  @wishlist = load_wishlist(user['user_id'])
  entry = params[:wishlist_item]
  
  if create(entry, user['user_id'], user['email'])
    session[:message] = 'The item was successfully added!'
  end
  redirect '/wishlist'
end

get '/wishlist/:userId/:itemId' do |userId, itemId|
  @item = FIREBASE.get_item_details(userId, itemId)
  @user = current_user

  erb :wishlist_item
end

post '/wishlist/claim-item' do 
  current_user_id = params[:current_user_id]
  list_item_user_id = params[:list_item_user_id]
  item_id = params[:item_id]
  FIREBASE.claim_item(current_user_id, list_item_user_id, item_id) 
  status 201
end
