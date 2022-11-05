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

require_relative 'FIREBASE_db'


base_uri = "https://nifty-7b5da-default-rtdb.FIREBASEio.com/"
FIREBASE = FirebaseService.new(base_uri)

USERS = YAML.load_file(File.join(__dir__, '/db/users.yml'))

def db_save(wishlist, usr_email)
  File.open(File.join(__dir__, "/db/wishlist-#{usr_email}.yml"), 'w') do |file|
    YAML.dump(wishlist, file)
  end
end

def user_db_save
  File.open(File.join(__dir__, '/db/users.yml'), 'w') do |file|
    YAML.dump(USERS, file)
  end
end

def create_yaml(usr_email)
   File.open(File.join(__dir__, "/db/wishlist-#{usr_email}.yml"), 'w') do |file|
    YAML.dump({}, file)
  end
end

def validate(input)
  return unless input.strip.empty?

  session[:error] = 'Please provide a valid wishlist item.'
  redirect '/wishlist'
end

def url?(input)
  a_url = input =~ /\A#{URI::DEFAULT_PARSER.make_regexp}\z/
  !!a_url
end

def create(input, wishlist)
  if url?(input)
    data = scrape(input)
    if data == :timeout_error
      session[:error] = 'Unable to retrieve url information, please submit information manually.'
      return false
    end
    data[:original_url] = input
  else
    data = { title: input }
  end
  data[:time_submitted] = Time.now.strftime("%b %d, %Y")
  unique_id = UUID.new.generate
  data[:id] = unique_id
  wishlist[unique_id] = data
end

#fb
def unique?(email)
  USERS.none? { |k, _| k == email }
end

def good?(password)
  session[:error] = 'The password needs to be minimum 5 characters long.' unless password.length >= 5
  password.length >= 5
end


def db_has_user?(email)
  USERS.any? { |k, _| k == email }
end

def registered?(email)
  registered_user = db_has_user?(email)
  session[:error] = 'This user has not been registered.' unless registered_user
  registered_user
end

def pw_match?(email, password)
  hsh_pw = BCrypt::Password.new(USERS[email][:password])
  session[:error] = 'The password is incorrect' unless hsh_pw == password
  hsh_pw == password
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
  user_found = FIREBASE.find_user(email)
  return false unless user_found && FIREBASE.pw_match?(email, password)

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
  # will fix this later
  true
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
  results = USERS.select do |email, _|
              email.match(possible_user)
            end.keys
end

def load_wishlist(email)
  FIREBASE.load_wishlist(email) || []
  # list = YAML.load_file(File.join(__dir__, "/db/wishlist-#{email}.yml"))
end

def claim_item(signedin_user, list_user, item_id)
  wishlist = load_wishlist(list_user)
  unless wishlist[item_id][:claimed_by]
    wishlist[item_id][:claimed_by] = signedin_user
  end
  db_save(wishlist, list_user)
  true
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
  redirect '/login' unless user_found

  session_token = generate_sess_token
  session_token[:email] = email
  FIREBASE.update_wishlist(user_found["id"], {session_id: session_token})
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
  p session[:token]
  loggedin_only
  @user = FIREBASE.current_user(session[:token])
  @wishlist = load_wishlist(@user[0])
  erb :wishlist
end

get '/wishlists/user/:email' do |email|
  @wishlist = load_wishlist(email)
  json @wishlist
end

get '/wishlist/search' do 
  possible_user = params[:email]
  json search_for_user(possible_user)
end

delete '/wishlist/:id' do |id|
  loggedin_only
  user = current_user
  @wishlist = load_wishlist(user[0])

  @wishlist.delete(id)
  db_save(@wishlist, user[0])
  status 204
end

post '/wishlist/new' do
  loggedin_only
  user = current_user
  @wishlist = load_wishlist(user[0])
  entry = params[:wishlist_item]
  if create(entry, @wishlist)
    session[:message] = 'The item was successfully added!'
    db_save(@wishlist, user[0])
  end
  redirect '/wishlist'
end

get '/wishlist/:user/:item' do |user, item|
  @wishlist = load_wishlist(user)
  @item = @wishlist[item]
  @user = user
  @signedin_user_email = current_user&.first
  erb :wishlist_item
end

post '/wishlist/claim-item' do 
  current_user = params[:current_user]
  list_item_user = params[:list_item_user]
  item_id = params[:item_id]
  claim_item(current_user, list_item_user, item_id) 
  status 201
end
