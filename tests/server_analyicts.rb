require File.expand_path '../test_helper.rb', __FILE__
require File.expand_path '../../mongo scripts/Analytics.rb', __FILE__
require 'csv'

class ServerClientKPITest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

	REMAKES = DB.collection("Remakes")
	USERS = DB.collection("Users")
	SHARES = DB.collection("Shares")
	VIEWS =  DB.collection("Views")
	SESSIONS = DB.collection("Sessions")
	START_DATE = Time.parse("20130206Z")
	END_DATE = Time.parse("20130209Z")

	test_USERS 		   			=  ["5332ec99f52d5c1ec2000017","53306186f52d5c6a14000006","53b9b6fd70b35d3c59000029"];
	HOT_TOPIC_STORY_ID 			=  BSON::ObjectId.from_string("5320cade72ec727673000402")
	test_STORY_ID      			=  BSON::ObjectId.from_string("52c18c569f372005e0000286")
	DUMB_AND_HELPLESS_STORY_ID  =  BSON::ObjectId.from_string("530dd1e5784380a058000601")
	STORIES                     =  [HOT_TOPIC_STORY_ID, test_STORY_ID];
	STORY_VIEWS = 1

	USER_ACTIVITY = Hash.new
	
	#USER_ACTIVITY["5332ec99f52d5c1ec2000017"] = {"2013-02-06" => {"sessions"=>2, remakes" => 5, "views" => 10, "shares" => 5}, "2013-02-07" => {"sessions"=>1, "remakes" => 6, "views" => 5, "shares" => 5}},
	#											 "2013-02-08" => {"sessions"=>2, "remakes" => 2, "views" => 5, "shares" => 5}, "2013-02-09" => {"sessions=>1, remakes" => 6, "views" => 3, "shares" => 5}

	#USER_ACTIVITY["53306186f52d5c6a14000006"] = {"2013-02-06" => {"sessions"=>1, "remakes" => 1, "views" => 2, "shares" => 5}, "2013-02-07" => {"sessions"=>1, "remakes" => 3, "views" => 7, "shares" => 5},
	#											"2013-02-08" => {"sessions"=>0 remakes" => 0, "views" => 3, "shares" => 5}, "2013-02-09" => {"sessions"=>2, "remakes" => 5, "views" => 5, "shares" => 4}}

	#USER_ACTIVITY["53b9b6fd70b35d3c59000029"] = {"2013-02-06" => {"remakes" => 5, "views" => 10, "shares" => 5}, "2013-02-07" => {"remakes" => 5, "views" => 3, "shares" => 1},
	#											"2013-02-08" => {"remakes" => 10, "views" => 4, "shares" => 1}, "2013-02-09" => {"remakes" => 5, "views" => 4, "shares" => 1}}

	#USER_ACTIVITY["53bc133e70b35d3c590000c5"] = {"2013-02-06" => {"remakes" => , "views" => 0, "shares" => 0}, "2013-02-07" => {"remakes" => 6, "views" => 10, "shares" => 1},
	#											"2013-02-08" => {"remakes" => 0, "views" => 0, "shares" => 0}, "2013-02-09" => {"remakes" => 20, "views" => 4, "shares" => 1}}

	def app
		Sinatra::Application
	end

	def setup 
		generateUserActivity
	end

	def teardown 
		REMAKES.remove(created_at: {"$gte"=>START_DATE , "$lt"=>add_days(END_DATE,1)})
		VIEWS.remove(start_time: {"$gte"=>START_DATE , "$lt"=>add_days(END_DATE,1)})
		SHARES.remove(created_at: {"$gte"=>START_DATE , "$lt"=>add_days(END_DATE,1)})
		SESSIONS.remove(start_time: {"$gte"=>START_DATE , "$lt"=>add_days(END_DATE,1)})
	end

	#measurements
   	def add_days(date,num_of_days)
   		#res = date + 86400*num_of_days
   		res = date + num_of_days*86400
   		return res
   end

   def add_weeks(date,num_of_weeks)
   		res = date + 604800*num_of_weeks
   		return res
    end

   	#activity	created_at	entity_id	story_id	remake_id	share_link	user_id	view_source
   	def generateUserActivity

   		#for i in 1..10 do
   		#	puts BSON::ObjectId.new
   		#end

   		CSV.foreach('test_case.csv', :headers => true) do |d|
   			
   			activity = d["activity"]
   			if activity == nil then
   				return
   			end

   			date = Time.parse(d["date"])
   			next_day = add_days(date,1)
   			created_at = Random.new.rand(date..next_day)

   			if activity == "remake" then
   				story_id = BSON::ObjectId.from_string(d["story_id"])
				if BSON::ObjectId.legal?(d["user_id"]) then
					user_id = BSON::ObjectId.from_string(d["user_id"])
				else
					user_id = d["user_id"]
				end

   				remake_id = BSON::ObjectId.from_string(d["entity_id"])
   
   				share_link = d["share_link"]
   				render_start = d["render_start"]
   				render_end = d["render_end"]
   				
   				remake = {_id: remake_id, user_id: user_id, story_id: story_id, created_at: created_at, render_start: render_start}
   				if share_link != nil then
   					remake[:share_link] = share_link
   				end

   				if render_end != nil then
   					remake[:render_end] = render_end
   				end
				
				puts "generating remake: " + remake.to_s   					
				REMAKES.save(remake)

			elsif activity == "view" then 
				
				view_id = BSON::ObjectId.from_string(d["entity_id"])
				user_id = BSON::ObjectId.from_string(d["user_id"])
				story_id = BSON::ObjectId.from_string(d["story_id"])
				view_source = d["view_source"]
				
    			originating_screen = Random.new.rand(0..5)
    			total_duration = 30
    			playback_duration = 20

    			view = {_id:view_id, user_id:user_id, story_id:story_id, start_time:created_at, playback_duration: playback_duration,
    					 total_duration: total_duration, originating_screen: originating_screen, view_source: view_source}

    			remake_id = d["remake_id"]
				if remake_id != nil then
					view[:remake_id] = remake_id
				end

    			puts "generating view: " + view.to_s
    			VIEWS.save(view)

    		elsif activity == "share" then

				share_id = BSON::ObjectId.from_string(d["entity_id"])
				remake_id = BSON::ObjectId.from_string(d["remake_id"])
				user_id = BSON::ObjectId.from_string(d["user_id"])
				share = {_id:share_id, user_id:user_id , remake_id:remake_id, created_at:created_at, share_method: Random.new.rand(0..5)}
				puts "generating share: " + share.to_s
				SHARES.save(share)

			elsif activity == "session" then

				session_id = BSON::ObjectId.from_string(d["entity_id"])
				user_id = BSON::ObjectId.from_string(d["user_id"])
				duration_in_minutes = d["duration_in_minutes"].to_f
				session_start_time = created_at
				session_end_time = created_at + duration_in_minutes.to_f*60
				user_session = {_id: session_id, user_id:user_id, start_time:session_start_time, end_time: session_end_time, duration_in_minutes: duration_in_minutes}
				puts "generating user_session: " + user_session.to_s
				SESSIONS.save(user_session)
			end
			
   		end
   	end

	def test_get_good_remakes_sorted_by_date_buckets		
		data = Analytics.get_good_remakes_sorted_by_date_buckets(START_DATE,END_DATE,STORIES)
		expected_res = {"2013-02-06"=>5, "2013-02-07"=>6, "2013-02-08"=>1, "2013-02-09"=>8}
		for datum in data do
			date = datum["_id"]["date"].strftime "%Y-%m-%d"
			res = datum["list"].count
			assert_equal(expected_res[date],res)
		end
	end

	def test_gen_data_pct_of_shared_videos_out_of_all_created_movies
							  
		remakes_sorted_by_date_buckets = [{"_id"=>{"date"=>Time.parse("20130206Z")}, "list"=>[BSON::ObjectId('540d9fd4cbd4858b08000001'), BSON::ObjectId('540d9fd5cbd4858b08000003'), BSON::ObjectId('540d9fd6cbd4858b08000009'), BSON::ObjectId('540d9fd7cbd4858b0800000e'), BSON::ObjectId('540d9fd7cbd4858b08000012')]},
										  {"_id"=>{"date"=>Time.parse("20130207Z")}, "list"=>[BSON::ObjectId('540d9fdbcbd4858b0800002a'), BSON::ObjectId('540d9fd8cbd4858b08000015'), BSON::ObjectId('540d9fd8cbd4858b08000017'), BSON::ObjectId('540d9fd9cbd4858b0800001b'), BSON::ObjectId('540d9fdacbd4858b08000022'), BSON::ObjectId('540d9fdbcbd4858b08000025')]}]

    	all_shared_remakes_for_dates = [{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fdfcbd4858b0800003e')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fdbcbd4858b0800002a')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fdccbd4858b0800002f')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fdbcbd4858b08000025')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fdacbd4858b08000022')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fd8cbd4858b08000017')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fd6cbd4858b08000009')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fd9cbd4858b0800001b')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fd7cbd4858b0800000e')}},
										{"_id"=>{"remake_id"=>BSON::ObjectId('540d9fd5cbd4858b08000003')}}]

		expected_res = {"2013-02-06"=>[3, 5], "2013-02-07"=>[5, 6]}

    	res = Analytics.gen_data_pct_of_shared_videos_out_of_all_created_movies(START_DATE,END_DATE,remakes_sorted_by_date_buckets, all_shared_remakes_for_dates) 
    	assert_equal(expected_res,res)
	end


	def test_get_movie_making_users_sorted_by_date_buckets		
		data = Analytics.get_movie_making_users_sorted_by_date_buckets(START_DATE,END_DATE,STORIES)

		expected_res = {"2013-02-06"=>2, "2013-02-07"=>2, "2013-02-08"=>1, "2013-02-09"=>2}
		
		for datum in data do
			date = datum["_id"]["date"].strftime "%Y-%m-%d"
			res = datum["list"].uniq.count
			assert_equal(expected_res[date],res)
		end
	end 


	def test_get_data_pct_of_users_who_shared_at_list_once
		users_sorted_by_date_buckets = [{"_id"=>{"date"=>Time.parse("20130206Z")}, "list"=>["5332ec99f52d5c1ec2000017", "53306186f52d5c6a14000006"]},
										{"_id"=>{"date"=>Time.parse("20130207Z")}, "list"=>["5332ec99f52d5c1ec2000017", "53306186f52d5c6a14000006"]}]

		all_sharing_users_for_dates = [{"_id"=>{"user_id"=>"5332ec99f52d5c1ec2000017"}}]

		res = Analytics.get_data_pct_of_users_who_shared_at_list_once(START_DATE,END_DATE,users_sorted_by_date_buckets,all_sharing_users_for_dates)
	
		expected_res = {"2013-02-06"=>[1, 2], "2013-02-07"=>[1, 2]}
		assert_equal(expected_res,res)
	end 
	
	def test_get_view_distribution_by_view_source
		
		data = Analytics.get_view_distribution_by_view_source(START_DATE,END_DATE,STORIES)

		n_data = Hash.new
		for datum in data do
			date = datum["_id"]["date"].strftime "%Y-%m-%d"
			
			if n_data[date] == nil then 
				n_data[date] = Hash.new
			end
			
			story_id = datum["_id"]["story_id"].to_s

			if n_data[date][story_id] == nil then 
				n_data[date][story_id] =  Hash.new
			end
			
			view_source = datum["_id"]["view_source"]
			count = datum["count"]
			n_data[date][story_id][view_source] = count
		end
		
		expected_res1 = 3
		expected_res2 = 10

		res1 = n_data["2013-02-07"]["5320cade72ec727673000402"]["1"]
		res2 = n_data["2013-02-06"]["52c18c569f372005e0000286"]["0"]
		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)
	end

	def test_get_story_views_for_stories
		

		data = Analytics.get_story_views_for_stories(START_DATE,END_DATE,STORIES)

		n_data = Hash.new
		for datum in data do
			date = datum["_id"]["date"].strftime "%Y-%m-%d"
			
			if n_data[date] == nil then 
				n_data[date] = Hash.new
			end
			
			story_id = datum["_id"]["story_id"].to_s

			if n_data[date][story_id] == nil then 
				n_data[date][story_id] =  Hash.new
			end

			count = datum["count"]
			n_data[date][story_id] = count
		end

		expected_res1 = 1
		expected_res2 = 6

		res1 = n_data["2013-02-07"]["5320cade72ec727673000402"]
		res2 = n_data["2013-02-06"]["52c18c569f372005e0000286"]
		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)
	end

	def test_get_remake_views_for_stories
		

		data = Analytics.get_remake_views_for_stories(START_DATE,END_DATE,STORIES)

		n_data = Hash.new
		for datum in data do
			date = datum["_id"]["date"].strftime "%Y-%m-%d"
			
			if n_data[date] == nil then 
				n_data[date] = Hash.new
			end
			
			story_id = datum["_id"]["story_id"].to_s

			if n_data[date][story_id] == nil then 
				n_data[date][story_id] =  Hash.new
			end

			count = datum["count"]
			n_data[date][story_id] = count
		end

		expected_res1 = 4
		expected_res2 = 6

		res1 = n_data["2013-02-07"]["5320cade72ec727673000402"]
		res2 = n_data["2013-02-06"]["52c18c569f372005e0000286"]
		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)
	end

	def test_get_data_total_views_for_story_for_day
		
		#views_distribution_by_view_source = Analytics.get_view_distribution_by_view_source(START_DATE,END_DATE,STORIES)
		views_distribution_by_view_source = [{"_id"=>{"date"=>Time.parse("20130209Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402"), "view_source"=>"0"}, "count"=>2}, {"_id"=>{"date"=>Time.parse("20130209Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286"), "view_source"=>"1"}, "count"=>3}, {"_id"=>{"date"=>Time.parse("20130207Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402"), "view_source"=>"0"}, "count"=>2}, {"_id"=>{"date"=>Time.parse("20130208Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402"), "view_source"=>"0"}, "count"=>5}, {"_id"=>{"date"=>Time.parse("20130207Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402"), "view_source"=>"1"}, "count"=>3}, {"_id"=>{"date"=>Time.parse("20130209Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286"), "view_source"=>"0"}, "count"=>1}, {"_id"=>{"date"=>Time.parse("20130208Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286"), "view_source"=>"1"}, "count"=>3}, {"_id"=>{"date"=>Time.parse("20130206Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286"), "view_source"=>"0"}, "count"=>10}, {"_id"=>{"date"=>Time.parse("20130207Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286"), "view_source"=>"0"}, "count"=>3}, {"_id"=>{"date"=>Time.parse("20130207Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286"), "view_source"=>"1"}, "count"=>4}, {"_id"=>{"date"=>Time.parse("20130209Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402"), "view_source"=>"1"}, "count"=>2}, {"_id"=>{"date"=>Time.parse("20130206Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286"), "view_source"=>"1"}, "count"=>2}]

		#story_views = Analytics.get_story_views_for_stories(START_DATE,END_DATE,STORIES)
		story_views = [{"_id"=>{"date"=>Time.parse("20130209Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402")}, "count"=>1},
						{"_id"=>{"date"=>Time.parse("20130209Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286")}, "count"=>1},
						{"_id"=>{"date"=>Time.parse("20130208Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402")}, "count"=>3},
						{"_id"=>{"date"=>Time.parse("20130207Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286")}, "count"=>3},
						{"_id"=>{"date"=>Time.parse("20130207Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402")}, "count"=>1},
						{"_id"=>{"date"=>Time.parse("20130206Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286")}, "count"=>6}]
		
		#remake_views = Analytics.get_remake_views_for_stories(START_DATE,END_DATE,STORIES)
		remake_views = [{"_id"=>{"date"=>Time.parse("20130209Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402")}, "count"=>3},
						{"_id"=>{"date"=>Time.parse("20130209Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286")}, "count"=>3},
						{"_id"=>{"date"=>Time.parse("20130208Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402")}, "count"=>2},
						{"_id"=>{"date"=>Time.parse("20130208Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286")}, "count"=>3},
						{"_id"=>{"date"=>Time.parse("20130207Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286")}, "count"=>4},
						{"_id"=>{"date"=>Time.parse("20130207Z"), "story_id"=>BSON::ObjectId("5320cade72ec727673000402")}, "count"=>4},
						{"_id"=>{"date"=>Time.parse("20130206Z"), "story_id"=>BSON::ObjectId("52c18c569f372005e0000286")}, "count"=>6}]

		data = Analytics.get_data_total_views_for_story_for_day(START_DATE,END_DATE,story_views,remake_views,views_distribution_by_view_source,STORIES)

		expected_res1 = 4
		res1 = data["52c18c569f372005e0000286"]["2013-02-07"]["remake_views"]

		expected_res2 = 3
		res2 = data["5320cade72ec727673000402"]["2013-02-08"]["story_views"]

		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)
	end


	def test_get_avg_session_time_for_date_range
		

		data = Analytics.get_avg_session_time_for_date(START_DATE,END_DATE)
		final_data = Analytics.get_data_avg_session_time(START_DATE,END_DATE,data)

		expected_res1 = 10.0
		expected_res2 = 7.5

		res1 = final_data["2013-02-08"]
		res2 = final_data["2013-02-07"]

		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)
	end

	def test_get_failed_remakes_sorted_by_date_buckets
		

		data = Analytics.get_failed_remakes_sorted_by_date_buckets(START_DATE,END_DATE,STORIES)
		
		n_data = Hash.new
		for datum in data do
			date = datum["_id"]["date"].strftime "%Y-%m-%d"
			count = datum["list"].count
			n_data[date] = count
		end 

		expected_res1 = 3
		expected_res2 = 2

		res1 = n_data["2013-02-09"]
		res2 = n_data["2013-02-07"]

		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)
	end


	def test_get_all_remakes_sorted_by_date_buckets
		

		data = Analytics.get_all_remakes_sorted_by_date_buckets(START_DATE,END_DATE,STORIES)
		
		n_data = Hash.new
		for datum in data do
			date = datum["_id"]["date"].strftime "%Y-%m-%d"
			count = datum["list"].count
			n_data[date] = count
		end 

		expected_res1 = 11
		expected_res2 = 9

		res1 = n_data["2013-02-09"]
		res2 = n_data["2013-02-07"]

		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)
	end

	def test_get_data_pct_of_failed_remakes_per_day
		

		#failed_remakes = Analytics.get_failed_remakes_sorted_by_date_buckets(START_DATE,END_DATE,STORIES)
    	failed_remakes = [{"_id"=>{"date"=>Time.parse("20130209Z")}, "list"=>["540e1c2acbd485906b00000f", "540e1c2acbd485906b000012", "540e1c2acbd485906b000019"]},
							{"_id"=>{"date"=>Time.parse("20130208Z")}, "list"=>["540e1c2acbd485906b00000d"]},
							{"_id"=>{"date"=>Time.parse("20130207Z")}, "list"=>["540e1c2acbd485906b000006", "540e1c2acbd485906b000016"]},
							{"_id"=>{"date"=>Time.parse("20130206Z")}, "list"=>["540e1c2acbd485906b000003"]}]
    
	    #all_remakes = Analytics.get_all_remakes_sorted_by_date_buckets(START_DATE,END_DATE,STORIES)
	    all_remakes = [{"_id"=>{"date"=>Time.parse("20130209Z")}, "list"=>["540e1c2acbd485906b00000e", "540e1c2acbd485906b00000f", "540e1c2acbd485906b000010", "540e1c2acbd485906b000011", "540e1c2acbd485906b000012", "540e1c2acbd485906b000013", "540e1c2acbd485906b000018", "540e1c2acbd485906b000019", "540e1c2acbd485906b00001a", "540e1c2acbd485906b00001b", "540e1c2acbd485906b00001c"]},
						{"_id"=>{"date"=>Time.parse("20130208Z")}, "list"=>["540e1c2acbd485906b00000c", "540e1c2acbd485906b00000d"]},
						{"_id"=>{"date"=>Time.parse("20130207Z")}, "list"=>["540e1c2acbd485906b000006", "540e1c2acbd485906b000007", "540e1c2acbd485906b000008", "540e1c2acbd485906b000009", "540e1c2acbd485906b00000a", "540e1c2acbd485906b00000b", "540e1c2acbd485906b000015", "540e1c2acbd485906b000016", "540e1c2acbd485906b000017"]},
						{"_id"=>{"date"=>Time.parse("20130206Z")}, "list"=>["540e1c2acbd485906b000001", "540e1c2acbd485906b000002", "540e1c2acbd485906b000003", "540e1c2acbd485906b000004", "540e1c2acbd485906b000005", "540e1c2acbd485906b000014"]}]

	    data = Analytics.get_data_pct_of_failed_remakes_per_day(START_DATE,END_DATE,failed_remakes,all_remakes)
	  
	  	expected_res1 = [2,9]
		expected_res2 = [3,11]

		res1 = data["2013-02-07"]
		res2 = data["2013-02-09"]

		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)

	end

	def test_sort_users_by_number_of_remakes
		

		data = Analytics.sort_users_by_number_of_remakes(START_DATE,END_DATE)

		n_data = Hash.new
		data.each do |key, value|
			num_of_remakes = key
			num_of_users = value.count
			n_data[num_of_remakes] = num_of_users
		end

		expected_res1 = 1
		expected_res2 = 1

		res1 = n_data[13]
		res2 = n_data[7]

		assert_equal(expected_res1,res1)
		assert_equal(expected_res2,res2)
	end

	def test_get_users_for_date_range
		 
		res = Analytics.get_users_for_date_range(START_DATE,END_DATE)
		expected_res = 3
		assert_equal(expected_res,res)
	end

	def test_get_user_distibution_per_number_of_remakes
		
		res = Analytics.get_user_distibution_per_number_of_remakes(START_DATE,END_DATE,3)
		expected_res = {0=>1, 1=>0, 2=>0, "3 and more"=>2}
		assert_equal(expected_res,res)
	end
end




