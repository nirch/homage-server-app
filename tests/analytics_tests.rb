require File.expand_path '../test_helper.rb', __FILE__

class AnalyticsTest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

	REMAKES = DB.collection("Remakes")
	USERS = DB.collection("Users")
	SHARES = DB.collection("Shares")

	def app
		Sinatra::Application
	end

	def setup 

	end

	def test_create_new_share

		remake_id = "5332ecd18bb1eb2bd1000001"
		user_id = "5332ecd18bb1eb2bd1000001"
		share_method = 2

		# Making the call to the server
		post '/remake/share', {:remake_id => remake_id , :user_id => user_id, :share_method => share_method}

		# Checking the response
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    assert_equal remake_id, json_response["remake_id"]["$oid"]
	    assert_equal user_id, json_response["user_id"]["$oid"]
	    assert_equal share_method, json_response["share_method"]
	    
	    # Checking the DB	    
	    share_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
	    @share = SHARES.find_one(share_id)
	    assert @share
	end

	def teardown
		if @share then
			SHARES.remove({_id: @share["_id"]})
			share = SHARES.find_one(@share["_id"])
	    	assert_nil share
		end
	end
end