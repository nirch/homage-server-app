require File.expand_path '../test_helper.rb', __FILE__

class AnalyticsTest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

	REMAKES = DB.collection("Remakes")
	USERS = DB.collection("Users")
	SHARES = DB.collection("Shares")
	VIEWS =  DB.collection("Views")
	SESSIONS = DB.collection("Sessions")

	@@start_date = Time.parse("2014070Z")
	@@end_date = Time.parse("20140715Z")
	@@launch_date = Time.parse("20140430")

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

	def test_start_stop_new_video_view
		view_id =   "5332ecd18bb1eb2bd1000333"
		remake_id = "5385affd70b35d7ebc0000eb"
		user_id = "5332ecd18bb1eb2bd1000777"
		playback_event = 0

		# Making the call to the server
		post '/remake/view', {:remake_id => remake_id , :user_id => user_id, :view_id => view_id, :playback_event => playback_event}

		# Checking the response
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    assert_equal remake_id, json_response["remake_id"]["$oid"]
	    assert_equal user_id, json_response["user_id"]["$oid"]

	    # Checking the DB	    
	    view_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
	    @view = VIEWS.find_one(view_id)
	    assert @view

	    #adding stop event details
	    playback_event = 1
		playback_duration = 50
		total_duration = 60

		# Making the call to the server
		post '/remake/view', {:remake_id => remake_id , :user_id => user_id, :view_id => view_id, :playback_event => playback_event,
		 :playback_duration => playback_duration, :total_duration => total_duration}

		 # Checking the response
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    assert_equal remake_id, json_response["remake_id"]["$oid"]
	    assert_equal user_id, json_response["user_id"]["$oid"]
	    assert_equal playback_duration, json_response["playback_duration"]
	    assert_equal total_duration, json_response["total_duration"]
	    
	    # Checking the DB	    
	    view_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
	    @view = VIEWS.find_one(view_id)
	    assert @view
	end

	def test_start_stop_user_session
		session_id = "5332ecd18bb1eb2bd1002222"
		user_id = "5332ecd18bb1eb2bd1003333"

		# Making the call to the server
		post '/user/begin', {:session_id => session_id , :user_id => user_id}

		# Checking the response
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    assert_equal user_id, json_response["user_id"]["$oid"]
	    
	    # Checking the DB	    
	    session_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
	    @session = SESSIONS.find_one(session_id)
	    assert @session

	    # Making the call to the server
		post '/user/end', {:session_id => session_id , :user_id => user_id}

		# Checking the response
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    assert_equal user_id, json_response["user_id"]["$oid"]
	    
	    # Checking the DB	    
	    session_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
	    @session = SESSIONS.find_one(session_id)
	    assert @session
	end



	def teardown
		#if @share then
		#	SHARES.remove({_id: @share["_id"]})
		#	share = SHARES.find_one(@share["_id"])
	    #	assert_nil share
		#end

		#if @view then
		#	VIEWS.remove({_id: @view["_id"]})
		#	view = VIEWS.find_one(@view["_id"])
	    #	assert_nil view
		#end

		#if @session then
			#SESSIONS.remove({_id: @session["_id"]})
			#session = SESSIONS.find_one(@session["_id"])
	    	#assert_nil session
		#end
	end
end