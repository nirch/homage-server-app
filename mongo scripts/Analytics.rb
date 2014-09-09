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

   
  def self.get_good_remakes_sorted_by_date_buckets(start_date,end_date,stories_array)
    match = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, share_link: {"$exists"=>true}, story_id: {"$in"=> stories_array}}}

    proj1={"$project" => {"_id" => 1, "created_at" => 1, 
      "h" => {"$hour" => "$created_at"}, "m" => {"$minute" => "$created_at"}, "s" => {"$second" => "$created_at"}, "ml" => {"$millisecond" =>  "$created_at"}}}

    proj2={"$project" => {"_id" => 1, "created_at" => {"$subtract" => 
      ["$created_at", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => { "_id" => { "date" => "$created_at"}, "list" => {"$push" => "$_id"}}}
                  
    res = @@remakes_collection.aggregate([match,proj1,proj2,group])
    return res
  end

  def self.get_failed_remakes_sorted_by_date_buckets(start_date,end_date,stories_array)
    match = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, render_start: {"$exists"=>true}, render_end: {"$exists"=>false}, story_id: {"$in" => stories_array}}}

    proj1={"$project" => {"_id" => 1, "created_at" => 1, 
      "h" => {"$hour" => "$created_at"}, "m" => {"$minute" => "$created_at"}, "s" => {"$second" => "$created_at"}, "ml" => {"$millisecond" =>  "$created_at"}}}

    proj2={"$project" => {"_id" => 1, "created_at" => {"$subtract" => 
      ["$created_at", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => { "_id" => { "date" => "$created_at"}, "list" => {"$push" => "$_id"}}}
                  
    res = @@remakes_collection.aggregate([match,proj1,proj2,group])
    return res
  end


   def self.get_all_remakes_sorted_by_date_buckets(start_date,end_date,stories_array)
    match = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, render_start: {"$exists"=>true}, story_id: {"$in" => stories_array}}}

    proj1={"$project" => {"_id" => 1, "created_at" => 1, 
      "h" => {"$hour" => "$created_at"}, "m" => {"$minute" => "$created_at"}, "s" => {"$second" => "$created_at"}, "ml" => {"$millisecond" =>  "$created_at"}}}

    proj2={"$project" => {"_id" => 1, "created_at" => {"$subtract" => 
      ["$created_at", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => { "_id" => { "date" => "$created_at"}, "list" => {"$push" => "$_id"}}}
                  
    res = @@remakes_collection.aggregate([match,proj1,proj2,group])
    return res
  end

  def self.get_movie_making_users_sorted_by_date_buckets(start_date,end_date,stories_array)
    date_range = {"$match" => { created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, story_id: {"$in"=> stories_array}}}

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
    while date <= end_date do
      shares_for_day = 0
      if user_buckets_by_dates[date] then
        for user in user_buckets_by_dates[date] do
          if shares_for_user[user] then
            shares_for_day +=1
          end
        end
      end

      key = date.strftime("%Y-%m-%d")
      if user_buckets_by_dates[date] then 
        final_data[key] = [shares_for_day, user_buckets_by_dates[date].count]
      end 
      date = add_days(date,1)
    end

    puts "final data ===== get_data_pct_of_users_who_shared_at_list_once: "
    puts final_data
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
    while date <= end_date do
      shares_for_day = 0

      if remake_bucket_by_dates[date] then
        puts remake_bucket_by_dates[date]
        for remake in remake_bucket_by_dates[date] do
          if shares_for_remake[remake] then
            shares_for_day +=1
          end
        end
      end

      key = date.strftime("%Y-%m-%d")
      if remake_bucket_by_dates[date] then 
        final_data[key] = [shares_for_day, remake_bucket_by_dates[date].count]
      end 
      date = add_days(date,1)
    end

    puts "final data ===== gen_data_pct_of_shared_videos_out_of_all_created_movies: "
    puts final_data
    return final_data
  end

  def self.get_active_stories_array
    return @@stories_collection.find({active: true}, {fields: {}}).flat_map(&:values)
  end

  def self.get_remake_views_for_stories(start_date,end_date,stories_array)
    remake_views_match = {"$match" => {start_time:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, story_id: {"$in"=> stories_array}, remake_id: {"$exists" => true}}}

    proj1={"$project" => { "_id" => 1, "start_time" => 1, "remake_id" => 1, "story_id" => 1, "view_source"=> 1,
     "h" => {"$hour" => "$start_time"}, "m" => {"$minute" => "$start_time"}, "s" => {"$second" => "$start_time"}, "ml" => {"$millisecond" =>  "$start_time"}}}

    proj2={"$project" => { "_id" => 1, "story_id" => 1, "remake_id" => 1, "view_source" => 1, "start_time" => {"$subtract" => 
      ["$start_time", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => {"_id" => {"date" => "$start_time", "story_id" => "$story_id"}, "count" => {"$sum" => 1}}}

    return @@views_collection.aggregate([remake_views_match,proj1,proj2,group])
end
  
def self.get_story_views_for_stories(start_date,end_date,stories_array)
    story_views_match  = {"$match" => {start_time:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, story_id: {"$in"=> stories_array}, remake_id: {"$exists" => false}}}

    proj1={"$project" => { "_id" => 1, "start_time" => 1, "story_id" => 1, "view_source"=> 1,
     "h" => {"$hour" => "$start_time"}, "m" => {"$minute" => "$start_time"}, "s" => {"$second" => "$start_time"}, "ml" => {"$millisecond" =>  "$start_time"}}}

    proj2={"$project" => { "_id" => 1, "story_id" => 1, "view_source" => 1, "start_time" => {"$subtract" => 
      ["$start_time", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => {"_id" => {"date" => "$start_time", "story_id" => "$story_id"}, "count" => {"$sum" => 1}}}

    return @@views_collection.aggregate([story_views_match,proj1,proj2,group])
end

  def self.get_view_distribution_by_view_source(start_date,end_date,stories_array)
    views_match  = {"$match" => {start_time:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, story_id: {"$in"=> stories_array}}}
    proj1={"$project" => { "_id" => 1, "start_time" => 1, "story_id" => 1, "view_source" => 1,
     "h" => {"$hour" => "$start_time"}, "m" => {"$minute" => "$start_time"}, "s" => {"$second" => "$start_time"}, "ml" => {"$millisecond" =>  "$start_time"}}}

    proj2={"$project" => { "_id" => 1, "story_id" => 1, "view_source" => 1, "start_time" => {"$subtract" => 
      ["$start_time", {"$add" => ["$ml",  {"$multiply" => ["$s", 1000]},  {"$multiply" => ["$m",60,1000]}, {"$multiply" => ["$h", 60, 60, 1000]}]}]}}}

    group={"$group" => {"_id" => {"date" => "$start_time", "story_id" => "$story_id", "view_source" => "$view_source"}, "count" => {"$sum" => 1}}}

    return @@views_collection.aggregate([views_match,proj1,proj2,group])
  end


  def self.get_data_total_views_for_story_for_day(start_date,end_date,story_views,remake_views,views_distribution_by_view_source,stories)
     
    remake_views_for_stories = Hash.new
    for record in remake_views do
      story_id = record["_id"]["story_id"].to_s
      date = record["_id"]["date"].strftime("%Y-%m-%d")
      if !remake_views_for_stories[story_id] then 
        remake_views_for_stories[story_id] = Hash.new
      end
      remake_views_for_stories[story_id][date] = record["count"]
    end
    puts remake_views_for_stories

    story_views_for_stories = Hash.new
    for record in story_views do
      story_id = record["_id"]["story_id"].to_s
      date = record["_id"]["date"].strftime("%Y-%m-%d")
      if !story_views_for_stories[story_id] then 
        story_views_for_stories[story_id] = Hash.new
      end
      story_views_for_stories[story_id][date] = record["count"]
    end
    puts story_views_for_stories

    view_by_distribution_for_stories = Hash.new
    for record in views_distribution_by_view_source do
      story_id = record["_id"]["story_id"].to_s
      date = record["_id"]["date"].strftime("%Y-%m-%d")
      view_source = record["_id"]["view_source"]

      if !view_by_distribution_for_stories[story_id] then 
        view_by_distribution_for_stories[story_id] = Hash.new
      end

      if !view_by_distribution_for_stories[story_id][date] then 
        view_by_distribution_for_stories[story_id][date] = Hash.new
      end

      view_by_distribution_for_stories[story_id][date][view_source] = record["count"]
    end
    puts view_by_distribution_for_stories

    views_for_stories = Hash.new
    for bson_story_id in stories do
      story_id = bson_story_id.to_s
      views_for_stories[story_id] = Hash.new
      date = start_date
      while date<=end_date do
        data_for_date = Hash.new
        date_key = date.strftime("%Y-%m-%d")

        remake_views = 0
        if remake_views_for_stories[story_id] then 
          if remake_views_for_stories[story_id][date_key] then 
            remake_views = remake_views_for_stories[story_id][date_key]
          end
        end

        story_views = 0
        if story_views_for_stories[story_id] then 
          if story_views_for_stories[story_id][date_key] then 
            story_views = story_views_for_stories[story_id][date_key]
          end
        end

        view_source_distribution = Hash.new
        if view_by_distribution_for_stories[story_id] then 
          if view_by_distribution_for_stories[story_id][date_key] then 
            view_source_distribution = view_by_distribution_for_stories[story_id][date_key]
          end 
        end

        data_for_date["remake_views"] = remake_views
        data_for_date["story_views"] = story_views
        data_for_date.merge!(view_source_distribution)
        views_for_stories[story_id][date_key] = data_for_date
        date = add_days(date,1)
      end
      #puts "views_for_stories[" + story_id + "]: " + views_for_stories[story_id].to_s
    end
    
    #puts "views_for_stories: " + views_for_stories.to_s
    return views_for_stories
  end

  def self.get_remakes_grouped_by_users(start_date,end_date,stories_array)
    match = {"$match" => {created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, share_link: {"$exists"=>true}, story_id:{ "$in" => stories_array}}}  
    group = {"$group" => { "_id" => {"user_id" => "$user_id"}, "count" => {"$sum" => 1}}}            
    return @@remakes_collection.aggregate([match,group])
  end

  def self.sort_users_by_number_of_remakes(start_date,end_date)
    match = {"$match" => {created_at:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}, share_link: {"$exists"=>true}}}  
    group = {"$group" => { "_id" => {"user_id" => "$user_id"}, "count" => {"$sum" => 1}}}
    
    res = @@remakes_collection.aggregate([match,group])

    data = Hash.new
    for user in res do
      user_id = user["_id"]["user_id"]
      count = user["count"]
      if !data[count] then

        data[count] = Array.new
      end
      data[count].push(user_id)
    end
    return data
  end  

  def self.get_users_for_date_range(start_date,end_date)
    match = {"$match" => {start_time:{"$gte"=>start_date, "$lt"=>add_days(end_date,1)}}}
    group ={"$group" => {"_id" => {"user_id" => "$user_id"}}}  
    return @@sessions_collection.aggregate([match,group]).count
  end

  def self.get_user_distibution_per_number_of_remakes(start_date,end_date,more_than)

    final_data = Hash.new
    data = sort_users_by_number_of_remakes(start_date,end_date)

    users_made_remakes = 0
    data.each do |key, array| 
      users_made_remakes += array.count
    end

    total_active_users = get_users_for_date_range(start_date,end_date)
    users_wo_remakes = total_active_users - users_made_remakes
    final_data[0] = users_wo_remakes

    more_than_count = 0
    
    for i in 1..more_than-1
      final_data[i] = 0
    end

    data.each do |key, array|
      num_of_users = array.count

      if key < more_than then
        final_data[key] = num_of_users
      else 
        more_than_count += num_of_users
      end
    end

    more_than_key = more_than.to_s + " and more" 
    final_data[more_than_key] = more_than_count
    return final_data
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

  def self.get_data_avg_session_time(start_date,end_date,avg_session_time_for_date)   
    final_data = Hash.new
    
    for date in avg_session_time_for_date do
      _date = date["_id"]["date"]
      _date_key = _date.strftime("%Y-%m-%d")
      avg_session_time = date["avg_session_time"]
      final_data[_date_key] = avg_session_time
    end

    return final_data
  end

  #=====================================================================================
  #===================================  Final KPI's ====================================
  #=====================================================================================

  # % of shared videos out of all created movies for date
  def self.get_pct_of_shared_videos_for_date_range_out_of_all_created_movies(start_date,end_date,stories_array)  
    #res of this query returns all remakes for dates, sorted by date buckets: {"_id"=>{"date"=>2014-07-15 00:00:00 UTC}, "list"=>[BSON::ObjectId('53c524e670b35d0a7c00001a'), BSON::ObjectId('53c5633770b35d77a2000001')]}
    remakes_sorted_by_date_buckets = get_good_remakes_sorted_by_date_buckets(start_date,end_date,stories_array)

    # {"_id"=>{"remake_id"=>BSON::ObjectId('53bc0a2770b35d3c590000bf')}}
    all_shared_remakes_for_dates = get_shares_grouped_by_remake_id(start_date,end_date)
    
    final_data = gen_data_pct_of_shared_videos_out_of_all_created_movies(start_date,end_date,remakes_sorted_by_date_buckets, all_shared_remakes_for_dates)

    return final_data
  end

  # % of users that shared at list once for day out of all of active users
  def self.get_pct_of_users_who_shared_at_list_once_for_date_range(start_date,end_date,stories_array)
    users_sorted_by_date_buckets = get_movie_making_users_sorted_by_date_buckets(start_date,end_date,stories_array)

    puts "users_sorted_by_date_buckets"
    puts users_sorted_by_date_buckets

    all_sharing_users_for_dates = get_shares_grouped_by_user_id(start_date,end_date)

    puts "all_sharing_users_for_dates"
    puts all_sharing_users_for_dates

    final_data = get_data_pct_of_users_who_shared_at_list_once(start_date,end_date,users_sorted_by_date_buckets, all_sharing_users_for_dates)
    return final_data      
  end

  def self.get_total_views_for_story_for_date_range(start_date,end_date,stories_array)     
      if stories_array.empty? then
        stories_array = get_active_stories_array 
      end   

      views_distribution_by_view_source = get_view_distribution_by_view_source(start_date,end_date,stories_array)
      story_views = get_story_views_for_stories(start_date,end_date,stories_array)
      remake_views = get_remake_views_for_stories(start_date,end_date,stories_array)

      final_data = get_data_total_views_for_story_for_day(start_date,end_date,story_views,remake_views,views_distribution_by_view_source,stories_array)
      return final_data
  end

  def self.get_distribution_of_remakes_between_users_from_date(start_date,end_date,stories_array)
    remakes_grouped_by_users = get_remakes_grouped_by_users(start_date,end_date,stories_array)
    final_data = get_data_distribution_of_movie_makers(remakes_grouped_by_users)
    return final_data
  end
 
  def self.get_avg_session_time_for_date_range(start_date,end_date)
    avg_session_time_for_date = self.get_avg_session_time_for_date(start_date,end_date)
    final_data = get_data_avg_session_time(start_date,end_date,avg_session_time_for_date)
    return final_data
  end

  def self.get_data_pct_of_failed_remakes_per_day(start_date,end_date,failed_remakes,all_remakes)
    failed_remakes_bucket_by_dates = Hash.new
    all_remakes_bucket_by_dates = Hash.new

    for date in failed_remakes do
      failed_remakes_bucket_by_dates[date["_id"]["date"]] = date["list"]
    end 

    for date in all_remakes do 
      all_remakes_bucket_by_dates[date["_id"]["date"]] = date["list"]
    end 

    #sort remakes and shares to date buckets
    final_data = Hash.new  
    date = start_date
    
    # iterate per day 
    while date <= end_date do
      key = date.strftime("%Y-%m-%d")

      final_data[key] = []
      if all_remakes_bucket_by_dates[date] then
        if failed_remakes_bucket_by_dates[date] then 
          final_data[key] = [failed_remakes_bucket_by_dates[date].count, all_remakes_bucket_by_dates[date].count]
        else 
          final_data[key] = [0, all_remakes_bucket_by_dates[date].count]
        end
      end
      date = add_days(date,1)
    end
    return final_data
  end

  def self.get_pct_of_failed_remakes_for_date_range(start_date,end_date,stories_array)
    failed_remakes = get_failed_remakes_sorted_by_date_buckets(start_date,end_date,stories_array)
    puts "failed_remakes"
    puts failed_remakes
    all_remakes = get_all_remakes_sorted_by_date_buckets(start_date,end_date,stories_array)
    puts "all_remakes"
    puts all_remakes

    final_data = get_data_pct_of_failed_remakes_per_day(start_date,end_date,failed_remakes,all_remakes)
    puts "final_data: get_pct_of_failed_remakes_for_date_range"
    puts final_data
    return final_data
  end
end









