require 'mongo'
require 'date'
require 'time'
require 'json'
require 'sinatra'


module RemakeStatus
 New = 0
 InProgress = 1
 Rendering = 2
 Done = 3
 Timeout = 4
 Deleted = 5
end

class Analytics
   @@db
   @@remakes_collection
   @@shares_collection
   @@views_collection
   @@sessions_collection 

   def self.init_db(db)
       @@db = db
       @@remakes_collection = @@db.collection("Remakes")
       @@shares_collection = @@db.collection("Shares")
       @@views_collection = @@db.collection("views")
       @@sessions_collection = @@db.collection("Sessions")
   end

   #measurements
   def self.unique_shares_by(shares,id)
   	unique_shares = Hash.new
   	for share in shares do
   		if !unique_shares[share[id]] then
   			unique_shares[share[id]] = 1
   		end
   	end
   	return unique_shares
   end

   def self.unique_remakes_by(remakes,id)
   	unique_remakes = Hash.new
   	for remake in remakes do
   		if !unique_remakes[remake[id]] then
   			unique_remakes[remake[id]] = 1
   		end
   	end
   	return unique_remakes
   end

   def self.add_days(date,num_of_days)
   	#res = date + 86400*num_of_days
   	res = date + num_of_days*86400
   	return res
   end

   def self.add_weeks(date,num_of_weeks)
   	res = date + 604800*num_of_weeks
   	return res
   end

   def self.get_shares_for_day(date)
   	next_day = add_days(date,1)
   	total_shares = @@shares_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day})
   	return total_shares
   end

   def self.get_number_of_remakes_shared_at_least_once_for_day(date)
   	total_shares = get_shares_for_day(date)
      puts "total shares for today: " + total_shares.count.to_s
      unique_shares = unique_shares_by(total_shares,"remake_id")
      puts "to " + unique_shares.count.to_s + " unique remakes"
   	return unique_shares.count
   end

   def self.get_remakes_created_for_day(date)
   	next_day = add_days(date,1)
   	total_remakes = @@remakes_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day}, status: 3)
   end

   def self.get_all_done_remakes 
   	return $test_remakes.find(status: RemakeStatus::Done)
   end

   def self.get_number_of_users_who_shared_at_list_once_for_day(date)
     total_shares = get_shares_for_day(date)
     return unique_shares_by(total_shares,"user_id").count
   end

   def self.get_number_of_users_created_at_least_one_remake_for_day(date)
     next_day = add_days(date,1)
     remakes = @@remakes_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day}, status: 3)
     puts "remakes made today: " + remakes.count.to_s
     unique_remakes = unique_remakes_by(remakes,"user_id")
     puts "from " + unique_remakes.count.to_s + " users " 
     return unique_remakes.count
   end

   def self.get_number_of_views_for_story_for_day(date,story_id)
      next_day = add_days(date,1)
      views = @@views_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day}, story_id: story_id)
      return views.count
   end

   def self.get_views_for_remake_for_day(date,remake_id)
      next_day = add_days(date,1)
      views = @@views_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day}, remake_id: remake_id)
      return views.count
   end

   def self.get_views_for_story_for_day(date,story_id)
      next_day = add_days(date,1)
      views = @@views_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day}, story_id: story_id)
      return views.count
   end

   def self.get_number_of_views_for_user_for_day(date,user_id)
     next_day = add_days(date,1)
     views = @@views_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day}, user_id: user_id)
     return views.count
   end

   def self.get_number_of_active_users_for_day(date)
     next_day = add_days(date,1)
     sessions = @@sessions_collection.find(start_time: {"$gte"=>date, "$lt"=>next_day})
     return sessions.count
   end

   def self.get_number_of_failed_remakes_for_day(date)
      next_day = add_days(date,1)
      remakes = @@remakes_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day})
      failed_remakes = 0
      for remake in remakes do
         if remake["render_start"] && !remake["render_end"] then
            failed_remakes = failed_remakes + 1
         end
      end
      return failed_remakes
   end

   def self.get_number_of_succsessful_remakes_for_day(date)
      next_day = add_days(date,1)
      remakes = @@remakes_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day})
      return remakes.count - get_number_of_failed_remakes_for_day(date)
   end

   #KPI's
   # % of shared videos out of all created movies for date
   def self.get_pct_of_shared_videos_for_day_out_of_all_created_movies(date)
      puts "==== calculating pct of shared videos out of all created_movie for date: " + date.iso8601 + " ===="
   	shares = get_number_of_remakes_shared_at_least_once_for_day(date)
      puts "number of remakes shared today at least once: " + shares.to_s 
   	successful_remakes = get_number_of_succsessful_remakes_for_day(date)
      puts "number of successful remakes today: " + successful_remakes.to_s
      if successful_remakes != 0 then
         return shares.to_f / successful_remakes.to_f
      end
      return 0
   end

   # % of users that shared at list once for day out of all of active users
   def self.get_pct_of_users_who_shared_at_list_once_for_day(date)
      puts "calculating pct of users who shared at least once of out of all active users for date: " + date.iso8601
   	sharing_users = get_number_of_users_who_shared_at_list_once_for_day(date)
      puts "number of users shared at least once: " + sharing_users.to_s
   	active_users = get_number_of_active_users_for_day(date)
      puts "active users today: " + active_users.to_s
   	if active_users != 0 then 
         return sharing_users.to_f / active_users.to_f
      end
      return 0
   end

   # % users who made a video out of all active users for date 
   def self.get_pct_of_users_who_created_a_video_for_day(date)
      puts "calculating pct of users who created at least one remake out of all active users for date: " + date.iso8601
   	users_created_remake = get_number_of_users_created_at_least_one_remake_for_day(date)
      puts "users created at least one remake: " + users_created_remake.to_s
   	active_users = get_number_of_active_users_for_day(date)
      puts "active users today: " + active_users.to_s 
   	if active_users != 0 then 
         return users_created_remake.to_f / active_users.to_f
      end
      return 0  
   end

    def self.get_total_views_for_story_for_day(date,story_id)
      next_day = add_days(date,1)
      puts "here - story id: " + story_id.to_s
      story_id_bson = BSON::ObjectId.from_string(story_id.to_s)
      remakes = @@remakes_collection.find(created_at:{"$gte"=>date, "$lt"=>next_day}, story_id: story_id_bson)
      total_views_per_story = get_views_for_story_for_day(date,story_id_bson)
      for remake in remakes do
         remake_id = remake["_id"]
         views_per_remake = get_views_for_remake_for_day(date,remake_id)
         total_views_per_story = total_views_per_story + views_per_remake
      end
      return total_views_per_story
   end
end









