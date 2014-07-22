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
   def self.add_days(date,num_of_days)
   	#res = date + 86400*num_of_days
   	res = date + num_of_days*86400
   	return res
   end

   def self.add_weeks(date,num_of_weeks)
   	res = date + 604800*num_of_weeks
   	return res
   end


   #TODO: make KPI for failed remakes
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
    match = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, share_link: {"$exists"=>true}}}

    proj1={"$project" => {"_id" => 1, "created_at" => 1, 
      "h" => {"$hour" => "$created_at"}, "m" => {"$minute" => "$created_at"}, "s" => {"$second" => "$created_at"}, "ml" => {"$millisecond" =>  "$created_at"}}}

    proj2={"$project" => {"_id" => 1, "created_at" => {"$subtract" => 
      ["$created_at", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => { "_id" => { "date" => "$created_at"}, "list" => {"$push" => "$_id"}}}
                  
    res = @@remakes_collection.aggregate([match,proj1,proj2,group])
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

  def self.get_shares_grouped_by_remake_id(start_date,end_date)
    date_range = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}}}
    group = {"$group"=> {"_id" => {"remake_id" => "$remake_id"}}}
    return @@shares_collection.aggregate([date_range,group])
  end

  def self.get_shares_grouped_by_user_id(start_date,end_date)
    date_range = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}}}
    group = {"$group"=> {"_id" => {"user_id" => "$user_id"}}}
    return @@shares_collection.aggregate([date_range,group])
  end

  def self.get_data_pct_of_users_who_shared_at_list_once(start_date,end_date,users_sorted_by_date_buckets, all_sharing_users_for_dates)

    # sort remakes to date buckets
    user_buckets_by_dates = Hash.new
    for date in users_sorted_by_date_buckets do
      user_buckets_by_dates[date["_id"]["date"]] = date["list"].uniq
    end

    #see which remakes have been shared in this time period
    shares_for_user = Hash.new
    for share in all_sharing_users_for_dates do
      shares_for_user[share["_id"]["user_id"]] = 1
    end

    #prepare data for returning 
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

  def self.gen_data_pct_of_shared_videos_out_of_all_created_movies(start_date,end_date,remakes_sorted_by_date_buckets, all_shared_remakes_for_dates)
    # sort remakes to more conveinent data model with date as key: {2014-07-02 00:00:00 UTC=>[BSON::ObjectId('53b3b03a70b35d5c43000114'), BSON::ObjectId('53b3c14c70b35d5c43000115')]
    remake_bucket_by_dates = Hash.new
    for date in remakes_sorted_by_date_buckets do
      remake_bucket_by_dates[date["_id"]["date"]] = date["list"]
    end 

    #see which remakes have been shared in this time period, move to data model with remake_id as key
    shares_for_remake = Hash.new
    for remake in all_shared_remakes_for_dates do
      if (!shares_for_remake[remake["_id"]["remake_id"]]) then 
        shares_for_remake[remake["_id"]["remake_id"]] = 1
      end
    end 

    #sort remakes and shares to date buckets
    final_data = Hash.new  
    date = start_date
    
    # iterate per day 
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

  def self.get_active_stories_array
    return @@stories_collection.find({active: true}, {fields: {}}).flat_map(&:values)
  end

  def self.get_views_grouped_by_date_for_stories(start_date,end_date,story_array)
    match = {"$match" => {start_time:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, story_id: {"$in"=> story_array}}}

    proj1={"$project" => { "_id" => 1, "start_time" => 1, "remake_id" => 1, "story_id" => 1,
     "h" => {"$hour" => "$start_time"}, "m" => {"$minute" => "$start_time"}, "s" => {"$second" => "$start_time"}, "ml" => {"$millisecond" =>  "$start_time"}}}

    proj2={"$project" => { "_id" => 1, "story_id" => 1, "remake_id" => 1, "start_time" => {"$subtract" => 
      ["$start_time", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => {"_id" => {"date" => "$start_time", "story_id" => "$story_id"}, "count" => {"$sum" => 1}}}
    return @@views_collection.aggregate([match,proj1,proj2,group])
  end

  def self.get_data_total_views_for_story_for_day(start_date,end_date,views,stories)
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

  def self.get_remakes_grouped_by_users(start_date)
    match = {"$match" => {created_at:{"$gte"=>start_date}, share_link: {"$exists"=>true}}}  
    group={"$group" => { "_id" => {"user_id" => "$user_id"}, "count" => {"$sum" => 1}}}            
    return @@remakes_collection.aggregate([match,group])
  end

  def self.get_data_distribution_of_movie_makers(remakes_grouped_by_users)
    final_data = Hash.new
    for user in remakes_grouped_by_users do
      user_id = user["_id"]["user_id"].to_s
      remake_count = user["count"]
      final_data[user_id] = remake_count
    end
    return final_data
  end

  

  def self.get_avg_session_time_for_date(start_date,end_date)
    match = {"$match" => {start_time:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}}}
    proj1={"$project" => {"_id" => 1, "start_time" => 1, "duration_in_minutes" => 1, 
      "h" => {"$hour" => "$start_time"}, "m" => {"$minute" => "$start_time"}, "s" => {"$second" => "$start_time"}, "ml" => {"$millisecond" =>  "$start_time"}}}
    proj2={"$project" => {"_id" => 1, "duration_in_minutes" => 1, "remake_id" => 1, "start_time" => {"$subtract" => 
      ["$start_time", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}
    group={"$group" => {"_id" => {"date" => "$start_time"}, "avg_session_time" => {"$avg" => "$duration_in_minutes"}}}              
    return @@sessions_collection.aggregate([match,proj1,proj2,group])
  end

  def self.get_data_avg_session_time(avg_session_time_for_date)  
    final_data = Hash.new
    for date in avg_session_time_for_date do
      _date = date["_id"]["date"]
      avg_session_time = date["avg_session_time"]
      final_data[_date] = avg_session_time
    end
    return final_data
  end

   #KPI's
   # % of shared videos out of all created movies for date
  def self.get_pct_of_shared_videos_for_date_range_out_of_all_created_movies(start_date,end_date)  
    #res of this query returns all remakes for dates, sorted by date buckets: {"_id"=>{"date"=>2014-07-15 00:00:00 UTC}, "list"=>[BSON::ObjectId('53c524e670b35d0a7c00001a'), BSON::ObjectId('53c5633770b35d77a2000001')]}
    remakes_sorted_by_date_buckets = get_remakes_sorted_by_date_buckets(start_date,end_date)
    # {"_id"=>{"remake_id"=>BSON::ObjectId('53bc0a2770b35d3c590000bf')}}
    all_shared_remakes_for_dates = get_shares_grouped_by_remake_id(start_date,end_date)
    
    final_data = gen_data_pct_of_shared_videos_out_of_all_created_movies(start_date,end_date,remakes_sorted_by_date_buckets, all_shared_remakes_for_dates)
    return final_data
  end

  # % of users that shared at list once for day out of all of active users
  def self.get_pct_of_users_who_shared_at_list_once_for_date_range(start_date,end_date)
    users_sorted_by_date_buckets = get_movie_making_users_sorted_by_date_buckets(start_date,end_date)
    all_sharing_users_for_dates = get_shares_grouped_by_user_id(start_date,end_date)
    final_data = get_data_pct_of_users_who_shared_at_list_once(start_date,end_date,users_sorted_by_date_buckets, all_sharing_users_for_dates)
    return final_data      
  end

  def self.get_total_views_for_story_for_date_range(start_date,end_date,story_id)  
      stories = Array.new   
      if story_id == 0 then 
        stories = get_active_stories_array 
      else 
        story_id_bson = BSON::ObjectId.from_string(story_id.to_s)
        stories.push(story_id_bson)
      end   
      views = get_views_grouped_by_date_for_stories(start_date,end_date,stories)   
      final_data = get_data_total_views_for_story_for_day(start_date,end_date,views,stories)
      return final_data
  end

  def self.get_distribution_of_remakes_between_users_from_date(start_date)
    remakes_grouped_by_users = get_remakes_grouped_by_users(start_date)
    final_data = get_data_distribution_of_movie_makers(remakes_grouped_by_users)
    return final_data
  end
 
  def self.get_avg_session_time_for_date_range(start_date,end_date)
    avg_session_time_for_date = self.get_avg_session_time_for_date(start_date,end_date)
    puts avg_session_time_for_date
    final_data = get_data_avg_session_time(avg_session_time_for_date)
    return final_data
  end
end








