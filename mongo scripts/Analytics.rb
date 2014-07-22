require 'mongo'
require 'date'
require 'time'
require 'json'
require 'sinatra'


class Analytics
   @@db
   @@remakes_collection
   @@shares_collection
   @@views_collection
   @@sessions_collection 
   @@stories_collection

   def self.init_db(db)
       @@db = db
       @@remakes_collection = @@db.collection("Remakes")
       @@shares_collection = @@db.collection("Shares")
       @@views_collection = @@db.collection("Views")
       @@sessions_collection = @@db.collection("Sessions")
        @@stories_collection = @@db.collection("Stories")
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


   def self.get_number_of_failed_remakes_for_date_range(start_date,end_date)
     query_end_date = add_days(end_date,1)
      remakes = @@remakes_collection.find(created_at:{"$gte"=>start_date, "$lt"=>query_end_date})
      failed_remakes = 0
      for remake in remakes do
         if remake["render_start"] && !remake["render_end"] then
            failed_remakes = failed_remakes + 1
         end
      end
      return failed_remakes
   end

   def self.get_number_of_succsessful_remakes_for_date_range(start_date,end_date)
      query_end_date = add_days(end_date,1)
      remakes = @@remakes_collection.find(created_at: {"$gte"=>start_date, "$lt"=>query_end_date}, share_link: {"$exists"=>true})
      return remakes
   end

   
  def self.get_remakes_sorted_by_date_buckets(start_date,end_date)
    date_range = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}}}

    proj1={"$project" => {"_id" => 1, "created_at" => 1, 
      "h" => {"$hour" => "$created_at"}, "m" => {"$minute" => "$created_at"}, "s" => {"$second" => "$created_at"}, "ml" => {"$millisecond" =>  "$created_at"}}}

    proj2={"$project" => {"_id" => 1, "created_at" => {"$subtract" => 
      ["$created_at", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => { "_id" => { "date" => "$created_at"}, "list" => {"$push" => "$_id"}}}
                  
    res = @@remakes_collection.aggregate([date_range,proj1,proj2,group])
    return res
  end

  def self.get_movie_making_users_sorted_by_date_buckets(start_date,end_date)
    date_range = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}}}

    proj1={"$project" => {"_id" => 0, "created_at" => 1, "user_id" => 1,
      "h" => {"$hour" => "$created_at"}, "m" => {"$minute" => "$created_at"}, "s" => {"$second" => "$created_at"}, "ml" => {"$millisecond" =>  "$created_at"}}}

    proj2={"$project" => {"_id" => 0, "user_id" => "$user_id", "created_at" => {"$subtract" => 
      ["$created_at", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => { "_id" => { "date" => "$created_at"}, "list" => {"$push" => "$user_id"}}}
    
    res = @@remakes_collection.aggregate([date_range,proj1,proj2,group])
    return res
    
  end


   #KPI's
   # % of shared videos out of all created movies for date
  def self.get_pct_of_shared_videos_for_date_range_out_of_all_created_movies(start_date,end_date)
    remakes_sorted_by_date_buckets = get_remakes_sorted_by_date_buckets(start_date,end_date)
  
    # sort remakes to date buckets
    remake_bucket_by_dates = Hash.new
    for date in remakes_sorted_by_date_buckets do
      remake_bucket_by_dates[date["_id"]["date"]] = date["list"]
    end 

    group = {"$group"=> {"_id" => {"remake_id" => "$remake_id"}}}

    res = @@shares_collection.aggregate([group])

    #see which remakes have been shared in this time period
    shares_for_remake = Hash.new
    for remake in res do
      shares_for_remake[remake["_id"]["remake_id"]] = 1
    end 

    #sort remakes and shares to date buckets
    final_data = Hash.new  
    date = start_date
    while date != end_date do
      shares_for_day = 0
      if remake_bucket_by_dates[date] then
        for remake in remake_bucket_by_dates[date] do
          if shares_for_remake[remake] then
            shares_for_day +=1
          end
        end
      end

      if remake_bucket_by_dates[date] then 
        final_data[date] = [remake_bucket_by_dates[date].count,  shares_for_day]
      else 
        final_data[date] = [0,0]
      end 
      date = add_days(date,1)
    end
    return final_data
  end

  # % of users that shared at list once for day out of all of active users
  def self.get_pct_of_users_who_shared_at_list_once_for_date_range(start_date,end_date)
    users_sorted_by_date_buckets = get_movie_making_users_sorted_by_date_buckets(start_date,end_date)

    # sort remakes to date buckets
    user_buckets_by_dates = Hash.new
    for date in users_sorted_by_date_buckets do
      user_buckets_by_dates[date["_id"]["date"]] = date["list"].uniq
    end

    group = {"$group"=> {"_id" => {"user_id" => "$user_id"}}}

    res = @@shares_collection.aggregate([group])

    #see which remakes have been shared in this time period
      shares_for_user = Hash.new
      for share in res do
        shares_for_user[share["_id"]["user_id"]] = 1
      end

    #sort remakes and shares to date buckets
    final_data = Hash.new  
    date = start_date
    while date != end_date do
      shares_for_day = 0
      if user_buckets_by_dates[date] then
        for user in user_buckets_by_dates[date] do
          if shares_for_user[user] then
            shares_for_day +=1
          end
        end
      end

      if user_buckets_by_dates[date] then 
        final_data[date] = [user_buckets_by_dates[date].count,  shares_for_day]
      else 
        final_data[date] = [0,0]
      end 
      date = add_days(date,1)
    end
    return final_data   
  end

  
  def self.get_total_views_for_story_for_date_range(start_date,end_date,story_id)  
      stories = Array.new   
      if story_id == 0 then 
        stories = @@stories_collection.find({active: true}, {fields: {}}).flat_map(&:values)
        puts stories.to_a
      else 
        story_id_bson = BSON::ObjectId.from_string(story_id.to_s)
        stories.push(story_id_bson)
      end
      
      remakes = @@remakes_collection.find({created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, story_id: {"$in"=>stories}, share_link: {"$exists"=>true}}, {fields: {}}).flat_map(&:values)
      match = {"$match" => {start_time:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, story_id: {"$in"=> stories}}}
      
      proj1={"$project" => { "_id" => 1, "start_time" => 1, "remake_id" => 1, "story_id" => 1,
         "h" => {"$hour" => "$start_time"}, "m" => {"$minute" => "$start_time"}, "s" => {"$second" => "$start_time"}, "ml" => {"$millisecond" =>  "$start_time"}}}

      proj2={"$project" => { "_id" => 1, "story_id" => 1, "remake_id" => 1, "start_time" => {"$subtract" => 
      ["$start_time", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

      group={"$group" => {"_id" => {"date" => "$start_time", "story_id" => "$story_id"}, "count" => {"$sum" => 1}}}
                
      #init data model 
      views_for_dates = Hash.new
      for story_id in stories do
        views_for_dates[story_id] = Hash.new
        date = start_date
        while date!=end_date do
          views_for_dates[story_id][date] = 0
          date = add_days(date,1)
        end
      end    

      views = @@views_collection.aggregate([match,proj1,proj2,group])
      
      #fill data model
      for view in views do
        story_id = view["_id"]["story_id"]
        date = view["_id"]["date"]
        count = view["count"]
        views_for_dates[story_id][date] = count 
      end

      #post process for visualization
      final_data = Array.new
      for story_id in stories do
        story_hash = { name: story_id.to_s, data: views_for_dates[story_id] } 
        final_data.push(story_hash)
      end
      return final_data 
    end

  def self.get_distribution_of_remakes_between_users_from_date(start_date)
    match = {"$match" => {created_at:{"$gte"=>start_date}, share_link: {"$exists"=>true}}}
    
    group={"$group" => { "_id" => {"user_id" => "$user_id"}, "count" => {"$sum" => 1}}}
                
    users = @@remakes_collection.aggregate([match,group])

    final_data = Hash.new
    for user in users do
      user_id = user["_id"]["user_id"].to_s
      remake_count = user["count"]
      final_data[user_id] = remake_count
    end
    return final_data
  end

  def self.get_avg_session_time_for_date_range(start_date,end_date)
    match = {"$match" => {start_time:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}}}
   
    proj1={"$project" => {"_id" => 1, "start_time" => 1, "duration_in_minutes" => 1, 
      "h" => {"$hour" => "$start_time"}, "m" => {"$minute" => "$start_time"}, "s" => {"$second" => "$start_time"}, "ml" => {"$millisecond" =>  "$start_time"}}}

    proj2={"$project" => {"_id" => 1, "duration_in_minutes" => 1, "remake_id" => 1, "start_time" => {"$subtract" => 
      ["$start_time", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => {"_id" => {"date" => "$start_time"}, "avg_session_time" => {"$avg" => "$duration_in_minutes"}}}
                
    dates = @@sessions_collection.aggregate([match,proj1,proj2,group])
    
    final_data = Hash.new
    for date in dates do
      _date = date["_id"]["date"]
      avg_session_time = date["avg_session_time"]
      final_data[_date] = avg_session_time
    end
    return final_data
  end
end








