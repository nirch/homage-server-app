require 'time'
require 'date'
require 'mongo'
require 'json'
require 'uri'
require 'open-uri'


DB = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db()
REMAKES = DB.collection("Remakes")
USERS = DB.collection("Users")
SHARES = DB.collection("Shares")
VIEWS =  DB.collection("Views")
SESSIONS = DB.collection("Sessions")

START_DATE = Time.parse("20140701Z")
END_DATE = Time.parse("20140715Z")
MAX_VIEWS = 10
MAX_SHARES = 10
MAX_REMAKES = 10

def add_days(date,num_of_days)
   	#res = date + 86400*num_of_days
   	res = date + num_of_days*86400
   	return res
end

def add_weeks(date,num_of_weeks)
   	res = date + 604800*num_of_weeks
   	return res
end

def users_for_remakes(remakes)
	users = Hash.new	
	for remake in remakes do
		user_id = remake["user_id"].to_s
		if !users[user_id] then
			users[user_id] = 1
		end
	end

	return users
end

def gen_session_for_user(user_id,session_start_time,session_end_time)
	session_id = BSON::ObjectId.new
	duration_in_seconds = session_end_time - session_start_time;
	duration_in_minutes = duration_in_seconds.to_f/60
	user_session = {_id: session_id, user_id:user_id, start_time:session_start_time, end_time: session_end_time, duration_in_minutes: duration_in_minutes}
	user_session_objectId = SESSIONS.save(user_session)
end


def gen_views_for_remake(remake_id,story_id,user_id,num_of_views_for_remake,fake_session_end)
    remake = REMAKES.find_one(_id: remake_id)
    remake_created_at = remake["created_at"]

    total_duration = 30
    playback_duration = 20
    max_time_for_view = fake_session_end

    for i in 0..num_of_views_for_remake do
    	view_start_time = Random.new.rand(remake_created_at..max_time_for_view)
    	view_id = BSON::ObjectId.new
    	view = {_id:view_id, user_id:user_id , story_id:story_id, remake_id:remake_id, start_time:view_start_time, playback_duration: playback_duration, total_duration: total_duration}
    	view_objectId = VIEWS.save(view)
    end
end

def gen_shares_for_remake(remake_id,user_id,num_of_shares_for_remake,fake_session_end)
    remake = REMAKES.find_one(_id: remake_id)
    remake_created_at = remake["created_at"]

    max_time_for_share = fake_session_end
    
    for i in 0..num_of_shares_for_remake do
    	share_id = BSON::ObjectId.new
    	share_time = Random.new.rand(remake_created_at..max_time_for_share)
    	share = {_id:share_id, user_id:user_id , remake_id:remake_id, created_at:share_time, share_method: Random.new.rand(0..5)}
		share_objectId = SHARES.save(share)
	end
end

def gen_views_for_user(user_id,fake_session_start,fake_session_end,num_of_views)
	
	views_to_generate = num_of_views
	remakes = REMAKES.find(created_at:{"$gte"=>fake_session_start, "$lt"=>fake_session_end})
	
	for remake in remakes do
		remake_id = remake["_id"]
		story_id = remake["story_id"]
		if views_to_generate == 0 then
			return #no more views to generate
		end
		num_of_views_for_remake = Random.new.rand(0..views_to_generate)
		views_to_generate -= num_of_views_for_remake
		puts "generating " + num_of_views_for_remake.to_s + " views for remake: " + remake_id.to_s
		gen_views_for_remake(remake_id,story_id,user_id,num_of_views_for_remake,fake_session_end)
	end
end

def gen_shares_for_user(user_id,fake_session_start,fake_session_end,num_of_shares)

	shares_left_to_generate = num_of_shares 
	user_remakes = REMAKES.find(user_id: user_id,created_at:{"$gte"=>fake_session_start, "$lt"=>fake_session_end})
	for remake in user_remakes do
		remake_id = remake["_id"]
		if shares_left_to_generate == 0 then	
			return #no more views to generate
		end
		num_of_shares_for_remake = Random.new.rand(0..shares_left_to_generate)
		puts "generating " + num_of_shares_for_remake.to_s + " shares for remake: " + remake_id.to_s
		shares_left_to_generate -= num_of_shares_for_remake
		gen_shares_for_remake(remake_id,user_id,num_of_shares_for_remake,fake_session_end)
	end
end

def users_for_date(date)
	next_day = add_days(date,1)
	remakes_for_day = REMAKES.find(created_at:{"$gte"=>date, "$lt"=>next_day}, status: 3)
	puts "the total number of remakes for: " + date.iso8601 + " is: " + remakes_for_day.count.to_s
	users = users_for_remakes(remakes_for_day)
	puts "these remakes were made by: " + users.count.to_s + " users"
	return users
end

#=========================== MAIN =====================================

date = START_DATE
while date!=END_DATE do
	puts "===============  Good morning, today is: " + date.iso8601 + "======================"
	puts " "
	next_day = add_days(date,1)
	users = users_for_date(date)
	users.each {|user_id, value|
		puts "--- generating activity for user: " + user_id + " ------ "
		user_id_bson = BSON::ObjectId.from_string(user_id)
		first_remake_cursor = REMAKES.find(user_id: user_id_bson, created_at:{"$gte"=>date, "$lt"=>next_day}, status: 3).sort(created_at:1).limit(1)
		last_remake_cursor = REMAKES.find(user_id: user_id_bson, created_at:{"$gte"=>date, "$lt"=>next_day}, status: 3).sort(created_at:-1).limit(1)
		
		fake_session_start = 0 
		fake_session_end = 0

		for remake in first_remake_cursor do
			fake_session_start = remake["created_at"] - 300 # -5 minutes
		end

		for remake in last_remake_cursor do
			fake_session_end = remake["render_end"] +  300 # +5 minutes
		end

		puts "generating session from: " + fake_session_start.iso8601 + " to: " + fake_session_end.iso8601 
		gen_session_for_user(user_id_bson,fake_session_start,fake_session_end)

		num_of_views_to_generate = Random.new.rand(0..MAX_VIEWS)
		puts "generating " + num_of_views_to_generate.to_s + " views"
		gen_views_for_user(user_id_bson, fake_session_start, fake_session_end, num_of_views_to_generate)

		num_of_shares_to_generate = Random.new.rand(0..MAX_SHARES)
		puts "generating " + num_of_shares_to_generate.to_s + " shares"
		gen_shares_for_user(user_id_bson, fake_session_start, fake_session_end, num_of_shares_to_generate)

		puts " "
	}
	date = next_day
	puts " "
end