require File.expand_path '../test_helper.rb', __FILE__

class UserTest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

  USERS = DB.collection("Users")

  FACEBOOK_USER = { :email => "unit@test.com",
                  :is_public => "YES", 
                  :device => { :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" }, 
                  :facebook => { :id => "929292929299", :name => "Bla Bla", :first_name => "Nir" }
                }


	def app
		Sinatra::Application
	end

	def setup
    @delete_user = nil
  end

  def test_update_user_public_true
    put '/user', { :user_id => "nir@homage.it", :is_public => "YES" }
    json_response = JSON.parse(last_response.body)
    assert_equal "nir@homage.it", json_response["_id"]
    assert_equal true, json_response["is_public"]
  end

  def test_update_user_public_false
    put '/user', { :user_id => "nir@homage.it", :is_public => "NO" }
    json_response = JSON.parse(last_response.body)
    assert_equal "nir@homage.it", json_response["_id"]
    assert_equal false, json_response["is_public"]
  end

  def test_create_user_guest
    guest_user = {  :is_public => "YES", 
                    :device => {:name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" } 
                  }
    post '/user/v2', guest_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal true, json_response["is_public"]
    assert json_response["device"]
    assert_nil json_response["facebook"]

    user = USERS.find_one(user_id)
    assert user

    # deleting the user
    USERS.remove({_id: user_id})
    user = USERS.find_one(user_id)
    assert_nil user
  end

  def test_create_user_facebook_new
    post '/user/v2', FACEBOOK_USER

    # checking the response
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal true, json_response["is_public"]
    assert json_response["device"]
    assert json_response["facebook"]

    # checking that the user exists in the DB
    user = USERS.find_one(user_id)
    assert user

    # deleting the user
    USERS.remove({_id: user_id})
    user = USERS.find_one(user_id)
    assert_nil user
  end

  def test_create_user_facebook_login  
    post '/user/v2', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    new_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user/v2', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    login_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    # checking that that the new user and the loged-in user both have the same user id
    assert_equal new_user_id, login_user_id

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: login_user_id})
    user = USERS.find_one(login_user_id)
    assert_nil user
    user = USERS.find_one(new_user_id)
    assert_nil user
  end

  # def test_create_user_password_new
  # end

  # def test_create_user_password_login
  # end

  # def test_guest_to_facebook
  # end

  # def test_guest_to_password
  # end

  # def test_facebook_to_password
  # end

  # def test_password_to_facebook
  # end

  # def test_add_device_facebook
  # end

  # def test_add_device_password
  # end


  def test_create_user_old
    user_id = "delete@test.com"
    post '/user', { :user_id =>  user_id}
    json_response = JSON.parse(last_response.body)
    assert_equal user_id, json_response["_id"]
    assert_equal true, json_response["is_public"]

    # deleting the user
    USERS.remove({_id: user_id})
    user = USERS.find_one({_id: user_id})
    assert_nil(user)
  end

  def test_env
    get '/test/env'
    assert_equal 'test', last_response.body
  end

  def teardown
    if @delete_user then
      #puts "Deleting user: " + @delete_user
      #USERS.remove({_id: @delete_user})
    else
      #puts "no user to delete"
    end
  end

  # def test_with_params
  #   get '/meet', :name => 'Frank'
  #   assert_equal 'Hello Frank!', last_response.body
  # end

  # def test_with_rack_env
  #   get '/', {}, 'HTTP_USER_AGENT' => 'Songbird'
  #   assert_equal "You're using Songbird!", last_response.body
  # end
end