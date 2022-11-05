require 'firebase'
require 'bcrypt'
require 'uuid'

base_uri = "https://nifty-7b5da-default-rtdb.firebaseio.com/"


class FirebaseService 
  def initialize(base_uri)
    @base_uri = base_uri
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

  def find_user(email)
    users = @firebase.get("users")
    users.body.values.find do |account|
      account['email'] == email
    end
  end

  def pw_match?(email, password)
    db_password = find_user(email)["password"]
    BCrypt::Password.new(db_password) == password
  end

  def unique?(email)
    @firebase.get('users').body.values.none? do |account| 
      account['email'] == email 
    end
  end

  def current_user(token)
    return nil unless token
    @firebase.get('users').body.values.find do |account|
      account["session_id"]["token_id"] = token[:token_id]
    end
  end

  def add_to_wishlist(data, email)
    @firebase.push("#{email}-wishlist", data)
  end

  def load_wishlist(email)
    @firebase.get("#{email}-wishlist").body
  end

  def update_wishlist(user_id, data)
    @firebase.update("users/#{user_id}", data)
  end


end

fb_service = FirebaseService.new(base_uri)

# fb_service.create_user('andrew@gmail.com', 'testing123456!!')

# p fb_service.find_user('testemiall@gmail.com')

# p fb_service.pw_match?('testemiall@gmail.com', 'testing123456!!')
# p Firebase::Client.new(base_uri).get("users").body

  # :title: 
  # :description:
  # :image_url: 
  # :price: 
  # :original_url: 
  # :time_submitted: 