require File.expand_path '../test_helper.rb', __FILE__
require File.expand_path '../mongo scripts/Analytics.rb', __FILE__

class AnalyticsTest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

	REMAKES = DB.collection("Remakes")
	USERS = DB.collection("Users")
	SHARES = DB.collection("Shares")
	VIEWS =  DB.collection("Views")
	SESSIONS = DB.collection("Sessions")
	start_date = Time.parse("20140706Z")
	end_date = Time.parse("20140709Z")


	
	def app
		Sinatra::Application
	end

	def setup 
		
	end

	def test_pct_of_shared_videos_out_of_all_created_videos
		
		expected_res = 
		res = Analytics.get_pct_of_shared_videos_for_date_range_out_of_all_created_movies(start_date,end_date)
