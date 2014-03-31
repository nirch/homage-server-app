require File.expand_path '../test_helper.rb', __FILE__

class RemakeTest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

	REMAKES = DB.collection("Users")
	USERS = DB.collection("Users")
	
	DIVE_SCHOOL = BSON::ObjectId.from_string("52de83db8bc427751c000305") # Dive School
 	THE_OSCARS = BSON::ObjectId.from_string("52ee613cab557ec484000021") # The Oscars
 	STAR_WARS = BSON::ObjectId.from_string("52cddaf80fad07c3290001aa") # Star Wars
 	DIVE_SCHOOL_2 = BSON::ObjectId.from_string("5315c2d2717f5df24a0001a7") # Dive School 2
 	HOT_TOPIC = BSON::ObjectId.from_string("5320cade72ec727673000402") # Hot Topic
 	ALIENS = BSON::ObjectId.from_string("53206e5514b2ecc477000241") # Aliens
 	MONSTER_ATTACK = BSON::ObjectId.from_string("532f058a3f13af9af80001bb") # Monster Attack

	GUEST_USER =  {  :is_public => "YES", 
	                 :device => {:identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A43699715", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" } 
	              }


	def app
		Sinatra::Application
	end

	def setup
		# Creating a user for the testing (deleting him in the teardown)
   		post '/user/v2', GUEST_USER
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
	    @user = USERS.find_one(user_id)
	    assert @user

	    # Creating a remake for the testing (deleting him in the teardown)
	    post '/remake', {:story_id => DIVE_SCHOOL.to_s, :user_id => @user["_id"].to_s}
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
	    @remake = REMAKES.find_one(remake_id)
	    assert @remake
  	end


	def test_setup
		assert @user
		assert @remake
	end


  	def teardown
  		if @user then
	   		USERS.remove({_id: @user["_id"]})
	    	user = USERS.find_one(@user["_id"])
	    	assert_nil user
	    end

	    if @remake then
	   		USERS.remove({_id: @remake["_id"]})
	    	remake = USERS.find_one(@remake["_id"])
	    	assert_nil remake
	    end
    end
end