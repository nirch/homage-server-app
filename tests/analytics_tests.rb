require File.expand_path '../test_helper.rb', __FILE__

class AnalyticsTest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

	REMAKES = DB.collection("Remakes")
	USERS = DB.collection("Users")
	SHARES = DB.collection("Shares")
	VIEWS =  DB.collection("Views")
	SESSIONS = DB.collection("Sessions")
	IMPRESSIONS = DB.collection("Impressions")
	LIKES = DB.collection("Likes")
	
	def app
		Sinatra::Application
	end

	def setup 

	end

	def test_report_share

		share_id = BSON::ObjectId.new
		remake_id = BSON::ObjectId.new
		user_id = BSON::ObjectId.new
		share_method = 0
		share_link = "blabla/share_link"
		share_status = 0

		share = {share_id: share_id, remake_id: remake_id, user_id: user_id, share_method: share_method, share_link: share_link, share_status: share_status}

		# Making the call to the server
		post '/remake/share', share

		# Checking the response
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    assert_equal remake_id.to_s, json_response["remake_id"]["$oid"]
	    assert_equal user_id.to_s, json_response["user_id"]["$oid"]
	    assert_equal share_method, json_response["share_method"]
	    
	    # Checking the DB	    
	    share_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
	    @share = SHARES.find_one(share_id)
	    assert @share   
	end

	def test_report_remake_impression
		remake_id = BSON::ObjectId.from_string("5447ade3771ac11ef9000001")
		remake = REMAKES.find_one(remake_id)
		assert remake
	
		previous_web_impressions        = remake["web_impressions"] ? remake["web_impressions"] : 0
		previous_unique_web_impressions = remake["unique_web_impressions"] ? remake["unique_web_impressions"] : 0

	 	#first impression - test incrementations
		impression_id = BSON::ObjectId.new
		user_id = BSON::ObjectId.new
		orig_screen = 11
		origin_id = BSON::ObjectId.new

		impression_params = {impression_id: impression_id, remake_id: remake_id, user_id: user_id, originating_screen: orig_screen, origin_id: origin_id}
		post '/remake/impression' , impression_params

		@impressions = Array.new
		impression = IMPRESSIONS.find_one(impression_id)
		assert impression
		@impressions.push(impression)

	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    assert_equal remake_id.to_s, json_response["remake_id"]["$oid"]
	    assert_equal user_id.to_s, json_response["user_id"]["$oid"]

	    remake = REMAKES.find_one(remake_id)
	    assert remake["web_impressions"]
	    assert remake["unique_web_impressions"]
   
	    expected_res1 = previous_web_impressions + 1
	    expected_res2 = previous_unique_web_impressions + 1

	    assert_equal remake["web_impressions"] , expected_res1
	    assert_equal remake["unique_web_impressions"] , expected_res2

		#second impression - test that another impression from same user not treated as unique
		previous_web_impressions        = remake["web_impressions"]
	    previous_unique_web_impressions = remake["unique_web_impressions"]

		impression_id = BSON::ObjectId.new
	    impression_params = {impression_id: impression_id, remake_id: remake_id, user_id: user_id, originating_screen: orig_screen, origin_id: origin_id}
	    post '/remake/impression' , impression_params

	   	impression = IMPRESSIONS.find_one(impression_id)
		assert impression
		@impressions.push(impression)

	   	remake = REMAKES.find_one(remake_id)
	   	assert_equal remake["unique_web_impressions"] , previous_unique_web_impressions

	   	#third impression - test no user_id nor cookie_id is assumed as unique impression
	   	previous_web_impressions        = remake["web_impressions"]
	   	previous_unique_web_impressions = remake["unique_web_impressions"]
	   	
	   	impression_id = BSON::ObjectId.new
	    impression_params = {impression_id: impression_id, remake_id: remake_id, originating_screen: orig_screen, origin_id: origin_id}
	   	post '/remake/impression' , impression_params

	   	impression = IMPRESSIONS.find_one(impression_id)
		assert impression
		@impressions.push(impression)

	   	remake = REMAKES.find_one(remake_id)
	   	expected_res = previous_unique_web_impressions + 1
	   	assert remake["unique_web_impressions"] , expected_res
	end

	def test_remake_view
		remake_id = BSON::ObjectId.from_string("5447ade3771ac11ef9000001")
		remake = REMAKES.find_one(remake_id)
		assert remake

		previous_views = remake["views"] ? remake["views"] : 0
		previous_unique_views = remake["unique_views"] ? remake["unique_views"] : 0

		#first view event - start - test creation and incrementation of views and unique views
		view_id = BSON::ObjectId.new
		cookie_id = BSON::ObjectId.new
		orig_screen = 11
		origin_id = BSON::ObjectId.new

		view_params = {view_id: view_id, remake_id: remake_id, cookie_id: cookie_id, originating_screen: orig_screen, origin_id: origin_id, playback_event: 0}
		post '/remake/view' , view_params

		@view = VIEWS.find_one(view_id)
		
		#check prpoer creation
		assert @view
		assert @view["start_time"]
		assert @view["view_source"]

		remake = REMAKES.find_one(remake_id)

		#check incrementation of views, both unique and regular
		expected_res1 = previous_views + 1
		expected_res2 = previous_unique_views + 1
		assert_equal remake["views"] , expected_res1
		assert_equal remake["unique_views"] , expected_res2

		#second view event - update(stop) - before siginificant view_threshold
		previous_views = remake["views"]
		previous_unique_views = remake["unique_views"]
		previous_significant_views = remake["significant_views"] ? remake["significant_views"] : 0
		previous_unique_significant_views = remake["unique_significant_views"] ? remake["unique_significant_views"] : 0

		total_duration = 25
		playback_duration = 5

		view_params = {view_id: view_id, remake_id: remake_id, cookie_id: cookie_id, playback_duration: playback_duration, total_duration: total_duration, playback_event: 1}
		post '/remake/view' , view_params

		@view = VIEWS.find_one(view_id)
		assert @view
		
		# check proper update of record 
		assert @view["playback_duration"]
		assert @view["total_duration"] 
		
		remake = REMAKES.find_one(remake_id)

		#test remake record remains the same
		assert_equal previous_views , remake["views"]
		assert_equal previous_unique_views , remake["unique_views"]
		assert_equal previous_significant_views , remake["significant_views"]
		assert_equal previous_unique_significant_views , remake["unique_significant_views"]

	end

	def test_significant_remake_view
		remake_id = BSON::ObjectId.from_string("5447ade3771ac11ef9000001")
		remake = REMAKES.find_one(remake_id)
		assert remake
		
		view_id = BSON::ObjectId.new
		cookie_id = BSON::ObjectId.new
		orig_screen = 11
		origin_id = BSON::ObjectId.new

		previous_significant_views = remake["significant_views"] ? remake["significant_views"] : 0
		previous_unique_significant_views = remake["unique_significant_views"] ? remake["unique_significant_views"] : 0

		view_params = {view_id: view_id, remake_id: remake_id, cookie_id: cookie_id, originating_screen: orig_screen, origin_id: origin_id, playback_event: 0}
		post '/remake/view' , view_params

		total_duration = 25
		playback_duration = 15

		view_params = {view_id: view_id, remake_id: remake_id, cookie_id: cookie_id, playback_duration: playback_duration, total_duration: total_duration, playback_event: 1}
		post '/remake/view' , view_params

		@view = VIEWS.find_one(view_id)
		assert @view

		expected_res1 = previous_significant_views + 1
		expected_res2 = previous_unique_significant_views + 1

		remake = REMAKES.find_one(remake_id)

		# test incrementaion of both regular and unique significant views. 
		assert_equal expected_res1, remake["significant_views"]
		assert_equal expected_res2, remake["unique_significant_views"]

		# second update view event - now with bigger playbcak duration 

		previous_significant_views = remake["significant_views"]
		previous_unique_significant_views = remake["unique_significant_views"]

		total_duration = 25
		playback_duration = 24

		view_params = {view_id: view_id, remake_id: remake_id, cookie_id: cookie_id, playback_duration: playback_duration, total_duration: total_duration, playback_event: 1}
		post '/remake/view' , view_params

		@view = VIEWS.find_one(view_id)
		assert @view

		expected_res1 = previous_significant_views
		expected_res2 = previous_unique_significant_views

		remake = REMAKES.find_one(remake_id)
		assert_equal expected_res1, remake["significant_views"]
		assert_equal expected_res2, remake["unique_significant_views"]
	end
	    

	def test_start_stop_user_session
		session_id = BSON::ObjectId.new
		user_id = BSON::ObjectId.new

		# Making the call to the server
		post '/user/session_begin', {:session_id => session_id.to_s , :user_id => user_id.to_s}

		# Checking the response
	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]
	    assert_equal user_id.to_s, json_response["user_id"]["$oid"]
	    
	    # Checking the DB	    
	    @session = SESSIONS.find_one(session_id)
	    assert @session
	    assert @session["start_time"]

	    # test switching users (guest upgrades to logged-in user)
	    new_user_id = BSON::ObjectId.new
	    post '/user/session_update' , {:session_id => session_id.to_s, :user_id => new_user_id.to_s}

	    json_response = JSON.parse(last_response.body)
	    assert json_response["_id"]["$oid"]

	    @session = SESSIONS.find_one(session_id)
	    assert @session

	    refute_equal @session["user_id"] , user_id
		
		#wait to get significant session
		sleep(40)

		post '/user/session_end', {:session_id => session_id , :user_id => new_user_id}
	    
	    # Checking the DB	 
	    @session = SESSIONS.find_one(session_id)
	    assert @session
	    assert @session["duration_in_minutes"]

	end

	def test_remake_like_routes 
		cookie_id = BSON::ObjectId.new
		
		remake_id = BSON::ObjectId.from_string("5449057c771ac16073000001")
		remake = REMAKES.find_one(remake_id)
		assert remake
		previous_likes = remake["like_count"] ? remake["like_count"] : 0

		post '/remake/like' , {cookie_id: cookie_id, remake_id: remake_id}

		#test like
		@like = LIKES.find_one({cookie_id: cookie_id, remake_id: remake_id})
		assert @like
		assert_equal @like["like_state"] , true 

		expected_res = remake["like_count"] + 1
		assert expected_res , remake["like_count"]

		#test unlike
		remake = REMAKES.find_one(remake_id)
		previous_likes = remake["like_count"]

		post '/remake/unlike' , {cookie_id: cookie_id, remake_id: remake_id}

		@like = LIKES.find_one({cookie_id: cookie_id, remake_id: remake_id})
		assert @like
		assert_equal @like["like_state"] , false

		remake = REMAKES.find_one(remake_id)
		expected_res = previous_likes - 1 
		assert_equal expected_res , remake["like_count"] 
	end



	def teardown
		if @share then
			SHARES.remove({_id: @share["_id"]})
			share = SHARES.find_one(@share["_id"])
	    	assert_nil share
		end

		if @view then
			VIEWS.remove({_id: @view["_id"]})
			view = VIEWS.find_one(@view["_id"])
	    	assert_nil view
		end

		if @session then
			SESSIONS.remove({_id: @session["_id"]})
			session = SESSIONS.find_one(@session["_id"])
	    	assert_nil session
		end

		if @impressions then
			for impression in @impressions do
				IMPRESSIONS.remove({_id: impression["_id"]})
				impression = IMPRESSIONS.find_one(impression["_id"])
				assert_nil impression
			end
		end

		if @like then
			LIKES.remove({_id: @like["_id"]})
			like = LIKES.find_one(@like["_id"])
	    	assert_nil like
		end
	end
end