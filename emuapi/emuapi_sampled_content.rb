

def handle_upload_user_content(config, connection, already_sampled=false)
  # This handles the sampling of users' content
  # Some of the users (not all) will be requested by the server
  # To upload some of their content to s3.
  upload_user_content = config["upload_user_content"]
  sampled_info = connection.db().collection("config").find({"config_type"=> "sampled users", "client_name"=>"Emu iOS"}).to_a

  # This feature can be disabled completely for all future clients.
  if upload_user_content == nil or sampled_info.count != 1 or upload_user_content["enabled"] == false
    # Disable all sampling for all future content.
    config["upload_user_content"] = { "enabled"=>false, "reason"=>"not valid or disabled" }
    return
  end
  sampled_info = sampled_info[0]

  if already_sampled
    # If the user was already sampled in the past (or is currently already sampled),
    # ignore that user and tell that user not to change the info about sampling she
    # already got.
    config["upload_user_content"] = { "unchanged"=>true, "reason"=>"already sampled" }
    return
  end


  # Sample only some of the users (not everybody). Get info about last sampled user and
  # make a decision if to sample this user or not.
  
  # Check if first sample for today.
  right_now = Time.now.utc
  first_sample_time_for_today = sampled_info["first_sample_time_for_today"]
  last_sample_time = sampled_info["last_sample_time"]
  if first_sample_time_for_today == nil or last_sample_time == nil or !(right_now.to_date === first_sample_time_for_today.to_date)
      # Nothing sampled yet today. Do the first sample for today.
      connection.db().collection("config").update(
        {"config_type"=> "sampled users", "client_name"=>"Emu iOS"},
        {"$set"=>{
          "first_sample_time_for_today"=>right_now,
          "last_sample_time"=>right_now,
          "today_sampled_users_count"=>666
        }}
      )
    return
  end

  # Already sampled some users today. Check if need to sample this one.
  seconds_passed_since_last_sample = right_now.to_i - last_sample_time.to_i
  today_sampled_users_count = sampled_info["today_sampled_users_count"]

  if seconds_passed_since_last_sample <= sampled_info["min_seconds_interval_between_samples"]
    config["upload_user_content"] = { "enabled"=>false, "reason"=>"sampling interval" }
    return
  end

  print upload_user_content, "<><><><>"
  if today_sampled_users_count >= sampled_info["max_sampled_users_per_day"]
    config["upload_user_content"] = { "enabled"=>false, "reason"=>"enough sampling for today" }
    return
  end

  # Another sampled user for today.
  connection.db().collection("config").update(
    {"config_type"=> "sampled users", "client_name"=>"Emu iOS"},
    {
      "$set"=>{"last_sample_time"=>right_now}, 
      "$inc"=>{"today_sampled_users_count"=>1}
    }
  )

end