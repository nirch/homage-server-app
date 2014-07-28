require File.expand_path '../test_helper.rb', __FILE__
require File.expand_path '../mongo scripts/Analytics.rb', __FILE__

class KPITest < MiniTest::Unit::TestCase
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

	def test_pct_of_shared_videos_for_date_range_out_of_all_created_movies

	end

	def test_pct_of_users_who_shared_at_list_once_for_date_range

	end

	def test_total_views_for_story_for_date_range

	end

	def test_distribution_of_remakes_between_users_from_date

	end

	def test_avg_session_time_for_date_range
		
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