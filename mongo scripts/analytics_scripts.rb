require 'mongo'
require 'date'
require 'time'

module RemakeStatus
  New = 0
  InProgress = 1
  Rendering = 2
  Done = 3
  Timeout = 4
  Deleted = 5
end

#prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db

$test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db

#prod_shares = prod_db.collection("Shares")
$test_shares = $test_db.collection("Shares")

#prod_views = prod_db.collection("Views")
$test_views = $test_db.collection("Views")

#prod_user_sessions = prod_db.collection("Sessions")
$test_user_sessions = $test_db.collection("Sessions")

#prod_remakes = prod_db.collection("Remakes")
$test_remakes = $test_db.collection("Remakes")


#start_render_more_than_one_num = num_more_than_one(start_render_users)
#launch_date = Time.parse("20140430")
# Number of "disapointed" remakes, remakes that were clicked on create movie but were not done
#total_remakes = prod_remakes.find(created_at:{"$gte"=>launch_date})
#puts "Total number of remakes: " + total_remakes.count.to_s
#disapointed_remakes = Array.new
#for remake in total_remakes do
	#if remake["status"] != 3 && remake["render_start"] && !remake["render_end"] && !remake["share_link"] then
#	if remake["render_start"] && !remake["render_end"] then
#		disapointed_remakes.push(remake)
#	end
#end
#puts "Number of disapointed remakes: " + disapointed_remakes.count.to_s

#start_render_remakes = prod_remakes.find(created_at:{"$gte"=>launch_date}, render_start:{"$exists"=>1})
#puts "Number of remakes start render: " + start_render_remakes.count.to_s

#puts "=========================================="

#def map_remakes_to_users(remakes)
#	users = Hash.new
#	for remake in remakes do
#		if !users[remake["user_id"]] then
#			users[remake["user_id"]] = 1
#		else
#			users[remake["user_id"]] = users[remake["user_id"]] + 1
#		end
#	end
#	return users
#end

#doc = coll.find_one()
 
#doc['updated_at'].is_a?(Time)                     #=> true
#doc['updated_at'].to_s                            #=> "2013-10-07 22:43:52 UTC"
#doc['updated_at'].iso8601                         #=> "2013-10-07T22:43:52Z"
#doc['updated_at'].strftime("updated at %m/%d/%Y") #=> "updated at 10/07/2013"


#measurements
def unique_shares_by(shares,id)
	unique_shares = Hash.new
	for share in shares do
		if !unique_shares[share[id]] then
			unique_shares[share[id]] = 1
		end
	end
	return unique_shares
end

def unique_remakes_by(remakes,id)
	unique_remakes = Hash.new
	for remake in remakes do
		if !unique_remake[remake[id]] then
			unique_remake[remake[id]] = 1
		end
	end
	return unique_remakes
end

def add_days(date,num_of_days)
	#res = date + 86400*num_of_days
	res = date + num_of_days*86400
	return res
end

def add_weeks(date,num_of_weeks)
	res = date + 604800*num_of_weeks
	return res
end

def get_shares_for_day(date)
	next_day = add_days(date,1)
	total_shares = $test_shares.find(created_at:{"$gte"=>date, "$lt"=>next_day})
	return total_shares
end

def get_number_of_remakes_shared_at_least_once_for_day(date)
	total_shares = get_shares_for_day(date)
	return unique_shares_by(total_shares,"remake_id").count
end

def get_remakes_created_for_day(date)
	next_day = add_days(date,1)
	total_remakes = $test_remakes.find(created_at:{"$gte"=>date, "$lt"=>next_day}, status: RemakeStatus::Done)
end

def get_all_done_remakes 
	return $test_remakes.find(status: RemakeStatus::Done)

def get_number_of_users_who_shared_at_list_once_for_day(date)
	total_shares = get_shares_for_day(date)
	return unique_shares_by(total_shares,"user_id").count
end

def get_number_of_users_created_at_least_one_remake_for_day(date)
	next_day = add_days(date,1)
	remakes = $test_remakes.find(created_at:{"$gte"=>date, "$lt"=>next_day})
	return unique_remakes_by(remakes,"user_id").count

def get_number_of_views_for_story_for_day(date,story_id)
	next_day = add_days(date,1)
	views = $test_views.find(created_at:{"$gte"=>date, "$lt"=>next_day}, :story_id: story_id)
	return views.count
end

def get_views_for_remake_for_day(date,remake_id)
	next_day = add_days(date,1)
	views = $test_views.find(created_at:{"$gte"=>date, "$lt"=>next_day}, :remake_id: remake_id)
	return views.count
end

def get_total_views_for_story_for_day(date,story_id)
	next_day = add_days(date,1)
	remakes = $test_remakes.find(created_at:{"$gte"=>date, "$lt"=>next_day}, :story_id:story_id)
	total_views_per_story = get_views_for_story_for_day(date,story_id)
	for remake in remakes do
		remake_id = remake["_id"]
		views_per_remake = get_views_for_remake_for_day(date,remake_id)
		total_views_per_story = total_views_per_story + views_per_remake
	end
	return total_views_per_story
end

def get_number_of_views_for_user_for_day(date,user_id)
	next_day = add_days(date,1)
	views = $test_views.find(created_at:{"$gte"=>date, "$lt"=>next_day}, :user_id: user_id)
	return views.count
end

def get_number_of_active_users_for_day(date)
	next_day = add_days(date,1)
	sessions = $test_user_sessions.find(start_time:{"$gte"=>date, "$lt"=>next_day})
	return sessions.count
end

def get_number_of_failed_remakes_for_day(date)
	next_day = add_days(date,1)
	remakes = $test_remakes.find(created_at:{"$gte"=>date, "$lt"=>next_day})
	failed_remakes = 0
	for remake in remakes do
		if remake["render_start"] && !remake["render_end"] then
			failed_remakes = failed_remakes + 1
		end
	end
	return failed_remakes
end

def get_number_of_succsessful_remakes_for_day(date)
	next_day = add_days(date,1)
	remakes = $test_remakes.find(created_at:{"$gte"=>date, "$lt"=>next_day})
	return remakes.count - get_number_of_failed_remakes_for_day(date)
end

#KPI's
# % of shared videos
def get_pct_of_shared_videos_for_day_out_of_all_created_movies(date)
	shares = get_number_of_remakes_shared_at_least_once_for_day(date)
	succesful_remakes = get_number_of_succsessful_remakes_for_day(date)
	return shares / succesful_remakes
end

# % of users that shared at list once for day out of all of active users
def get_pct_of_users_who_shared_at_list_once_for_day(date)
	sharing_users = get_number_of_users_who_shared_at_list_once_for_day(date)
	active_users = get_number_of_active_users_for_day(date)
	return sharing_users / active_users
end

def get_pct_of_users_who_created_a_video_for_day(date)
	users_created_remake = get_number_of_users_created_at_least_one_remake_for_day(date)
	active_users = get_number_of_active_users_for_day(date)
	return users_created_remake / active_users
end


date = Time.parse("20140715Z")
res = get_remakes_shared_at_least_once_for_day(date)
puts "number of unique remakes shared the following day: " + res.to_s






