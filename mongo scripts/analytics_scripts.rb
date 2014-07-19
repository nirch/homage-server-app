require File.expand_path '../Analytics.rb', __FILE__

date = Time.parse("20140708Z")
START_DATE = Time.parse("20140701Z")
END_DATE = Time.parse("20140715Z")
turbo_ski_story_id = "5356dc94ebad7c3bf100015d"

DB = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db()
Analytics.init_db(DB)

def add_days(date,num_of_days)
   	#res = date + 86400*num_of_days
   	res = date + num_of_days*86400
   	return res
end

def add_weeks(date,num_of_weeks)
   	res = date + 604800*num_of_weeks
   	return res
end

#KPI's
# % of shared videos out of all created movies for date
#res = Analytics.get_pct_of_shared_videos_for_day_out_of_all_created_movies(date)
#puts "pct of shared videos out of all videos: " + res.to_s
#puts ""

# % of users that shared at least once out of all active users for date
#res = Analytics.get_pct_of_users_who_shared_at_list_once_for_day(date)
#puts "pct of users sharing videos: " + res.to_s

# % users who made a video out of all active users for date 
#res = Analytics.get_pct_of_users_who_created_a_video_for_day(date)
#puts "pct of users creating movies: " + res.to_s
#puts ""

# number of views for story
puts "Turbo ski story id: " + turbo_ski_story_id.to_s
res = Analytics.get_total_views_for_story_for_day(date,turbo_ski_story_id.to_s)
puts "total views for day: " + res.to_s

get_total_views_for_story_for_day_proc = Proc.new { |date, story_id| 
		Analytics.get_total_views_for_story_for_day(date,story_id) 
}

def prepare_data_for_date_range(proc,start_date,end_date)
	puts "preparing data between: " + start_date.iso8601 + " to: " + end_date.iso8601
	date = start_date
	data = Hash.new 
	while date!=end_date do
		value = proc.call(date)
		next_day = add_days(date,1)
		data[date] = value
		date = next_day
	end
	return data
end

#MAIN
data = prepare_data_for_date_range(get_total_views_for_story_for_day_proc,START_DATE,END_DATE)
data.each {|date , value|
	puts "date: " + date.iso8601 + " value: " + value.to_s
}




