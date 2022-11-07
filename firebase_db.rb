require 'firebase'
require 'bcrypt'
require 'uuid'

base_uri = "https://nifty-7b5da-default-rtdb.firebaseio.com/"


class FirebaseService 
  def initialize
    @base_uri = "https://nifty-7b5da-default-rtdb.firebaseio.com/"
    @firebase = Firebase::Client.new(@base_uri)
  end

  def generate_sess_token
    token = UUID.new.generate
    { token_id: token, time_created: Time.now }
  end

  def create_user(email, password)
    pw_digest = BCrypt::Password.create(password).to_s
    session_token = generate_sess_token
    session_token[:email] = email
  
    response = @firebase.push("users", { email: email, password: pw_digest, session_id: session_token })

    @firebase.update("users/#{response.body["name"]}", { user_id:  response.body["name"]})
    session_token
  end

  def find_user(query)
    users = @firebase.get("users")
    possibleUsers = users.body.values.select do |account|
      account['email'].include? query
    end
    possibleUsers.map {|acc| {email: acc['email'], user_id: acc['user_id']}}
  end
  

  def pw_match?(email, password)
    user = get_user(email)
    return false unless user
    db_password = user["password"]
    BCrypt::Password.new(db_password) == password
  end

  def unique?(email)
    user_db = @firebase.get('users').body
    return true unless user_db
    user_db.values.none? do |account| 
      account['email'] == email 
    end
  end

  def current_user(token)
    user = @firebase.get('users').body.values.find do |account|
      account['session_id']['token_id'] == token[:token_id] 
    end
  end

  def add_to_wishlist(data, user_id)
    response = @firebase.push("#{user_id}-wishlist", data)
    @firebase.update("#{user_id}-wishlist/#{response.body["name"]}", { item_id:  response.body["name"]})
  end

  def delete_item(user_id, item_id)
    @firebase.delete("#{user_id}-wishlist/#{item_id}")
  end

  def load_wishlist(user_id)
    wishlist = @firebase.get("#{user_id}-wishlist").body
    return nil unless wishlist
    return wishlist.values
  end

  def update_user_session(user_id, session)
    @firebase.update("users/#{user_id}", session)
  end

  def get_item_details(user_id, item_id) 
    @firebase.get("#{user_id}-wishlist/#{item_id}").body
  end

  def claim_item(current_user_id, list_item_user_id, item_id) 
    current_user_email = @firebase.get("users/#{current_user_id}").body['email']
    @firebase.update("#{list_item_user_id}-wishlist/#{item_id}", {claimed_by: {user_id: current_user_id, email: current_user_email }})
  end

   
  def get_user(email)
    @firebase.get('users').body.values.find do |account|
      account['email'] == email
    end
  end

end
