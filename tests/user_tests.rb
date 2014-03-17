require File.expand_path '../test_helper.rb', __FILE__

class UserTest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

  USERS = DB.collection("Users")

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

  def test_create_user
    user_id = "delete@test.com"
    post '/user', { :user_id =>  user_id}
    @delete_user = user_id
    json_response = JSON.parse(last_response.body)
    assert_equal user_id, json_response["_id"]
    assert_equal true, json_response["is_public"]
  end

  def test_env
    get '/test/env'
    assert_equal 'test', last_response.body
  end

  def teardown
    if @delete_user then
      #puts "Deleting user: " + @delete_user
      USERS.remove({_id: @delete_user})
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