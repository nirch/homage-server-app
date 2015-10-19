#encoding: utf-8
require_relative 'emuapi_config'
require_relative 'emuapi_sampled_content'
require_relative 'emuapi_localization'
require_relative 'emuapi_features'
require_relative '../emuconsole/logic/package'
require 'logger'

module BSON
    class ObjectId

      def converted_to_s
        @data.map {|e| v=e.to_s(16); v.size == 1 ? "0#{v}" : v }.join
      end

      # Monkey patching to_json so it will return
      # ObjectId as json and not as a simple string containg the oid
      def to_json(*a)
        "{\"$oid\": \"#{converted_to_s}\"}"
      end

      # Monkey patching as_json so it will return
      # ObjectId as json and not as a simple string containg the oid
      def as_json(options ={})
        {"$oid" => converted_to_s}
      end

    end
end

before do
  use_scratchpad = request.env['HTTP_SCRATCHPAD'].to_s
  if use_scratchpad == "true" and MongoMapper.connection.db().name != settings.emu_scratchpad.db().name then
    MongoMapper.connection = settings.emu_scratchpad
    MongoMapper.database = settings.emu_scratchpad.db().name
  elsif use_scratchpad != "true"  and MongoMapper.connection.db().name != settings.emu_public.db().name then
    MongoMapper.connection = settings.emu_public
    MongoMapper.database = settings.emu_public.db().name
  end
  # else public
end

get '/emu/ios' do
  @mixpanel_token = settings.emumixpanel_token
  @mixpanel_event = "Web:Emu:AppStoreRedirect"
  @redirect_url = "https://itunes.apple.com/app/id969789079"
  erb :redirect
end

get '/emu/android' do
  @mixpanel_token = settings.emumixpanel_token
  @mixpanel_event = "Web:Emu:PlayStoreRedirect"
  @redirect_url = "https://play.google.com/store/apps/details?id=im.emu.app.emu.prod"
  erb :redirect

end


# ---------------------------------------------
# /emuapi/packages/:filter 
#
# GET packages info.
# Will also include config info for the app.
get '/emuapi/packages/:filter' do
  #
  # prepare some required vars
  #
  filter_predicate = {}
  country_code = nil
  forced_location = params["l"]
  clear_gl_cache = params["glc"]
  geo_location_service = "localdb"
  client_version = request.env['HTTP_APP_VERSION_INFO'].to_s
  client_name = request.env['HTTP_APP_CLIENT_NAME'].to_s

  #
  # Geo location / country code
  #
  if forced_location == nil
    # look up user location using request ip address.
    geodb = settings.geodb
    country_code = geodb.lookup(request.ip)['country']['iso_code'] rescue nil
  else
    country_code = forced_location
    geo_location_service = "forced_param"
  end

  #
  # determine connection required (public/scratchpad)
  #
  connection = scratchppad_or_produdction_connection(request)

  #
  # Validate filter used
  #
  filter = params["filter"]
  if (filter !='full' && filter !='update') then oops_404 end

  #
  # Get the config information
  #
  config = connection.db().collection("config").find({"config_type"=> "app config", "client_name"=>"Emu iOS"}).to_a
  if (config.count < 1) then oops_500() end
  config = config.to_a[0]

  #
  # Mixed screen (TODO: should be deprecated with new design of the app)
  #
  mixed_screen = connection.db().collection("config").find({"config_type"=> "mixed screen", "client_name"=>"Emu iOS"}).to_a
  if (mixed_screen.count != 1)
    mixed_screen = {"enabled"=>false, "reason"=>"invalid config or disabled"}
  else
    mixed_screen = mixed_screen.to_a[0]  
  end
  
  # Handle sampled user content
  # TODO: this can be deprecated in a version or two.
  already_sampled_header = request.env['HTTP_USER_SAMPLED_BY_SERVER'].to_s
  already_sampled = already_sampled_header=="true"
  handle_upload_user_content(config, connection, already_sampled=already_sampled)

  #
  # Packages filters
  #
  if filter == "update"
    after = Integer(params[:after]) rescue 0
    filter_predicate["data_update_time_stamp"] = {"$gt"=>after}
  end

  # Filter by country code (geo location)
  countries_filter = countries_filter_by_country_code(country_code)
  if countries_filter != nil
    filter_predicate = filter_predicate.merge(countries_filter)
  end

  # Filter by features 
  # Packs can be marked with required_<platform>_version field
  # For required version X.Y the value will be 0000X_0000Y
  # For example, for a pack that requires iOS 2.13 client the pack will have the following field
  # required_ios_version="00002_00013"
  supported_features_filter = supported_features_filter_for_client(client_name, client_version)
  if supported_features_filter != nil
    filter_predicate = filter_predicate.merge(supported_features_filter)
  end

  # Get the packages
  logger.info "Packs filter: " + filter_predicate.to_s
  packages = connection.db().collection("packages").find(filter_predicate)
  packages = packages.to_a

  # Add some localisation info (if required)
  preffered_languages = request.env["HTTP_ACCEPT_LANGUAGE"]
  add_localization_info(config, connection, preffered_languages)

  # Localisation per emu
  add_localization_for_packs(packages, preffered_languages)

  # Merge config info with packages info
  result = Hash.new
  result = result.merge(config)
  result["packages_count"] = packages.count
  result["packages"] = packages
  result["mixed_screen"] = mixed_screen
  result["country_code"] = country_code
  result["geo_location_service"] = geo_location_service
  
  response.headers['content-type'] = 'application/json'

  return result.to_json()
end



# ---------------------------------------------
# /emuapi/unhide/packages/:code
#
# GET request to unhide a set of packages, given a code.
# Will return a list of packages oids to unhide + 
# some meta info about the packages (like name and update timestamp)
#
# If relevant code is not enabled or available in the codes collection
# 404 error message will be returned.
get '/emuapi/unhide/packages/:code' do
  connection = scratchppad_or_produdction_connection(request)

  # Search for the provided unhide-packs code.
  code = params["code"]
  predicate = {"code_enabled"=>true, "unhide_code"=>code}
  response = connection.db().collection("codes").find_one(predicate)
  
  # If no such enabled code, return a 404 error
  if response == nil
    oops_404
  end

  # We have a legit code. 
  # Gather some more info about the packs and return it with the response.
  # Can be useful for clients that don't have the packs and need to fetch them
  # specifically.
  interesting_fields = { 
    "name" => true, 
    "last_update_timestamp" => true,
    "label" => true
  }
  list_of_packs_oids = response["unhides_packages"].map{ |oid| BSON::ObjectId.from_string(oid) }
  packs_predicate = {"_id"=> {"$in"=>list_of_packs_oids}}
  packages = connection.db().collection("packages").find(packs_predicate, {:fields=>interesting_fields})
  response["packages_info"] = packages

  return response.to_json()
end




# Updating the push token to 
put '/emuapi/user/push_token' do
  # input
  device_identifier = BSON::ObjectId.from_string(params[:device_identifier])
  device_name = BSON::ObjectId.from_string(params[:device_name])
  device_os = BSON::ObjectId.from_string(params[:device_os])
  push_token = BSON::ObjectId.from_string(params[:push_token])

  connection = settings.emu_public
  use_scratchpad = request.env['HTTP_SCRATCHPAD'].to_s  
  if use_scratchpad == "true"
    connection = settings.emu_scratchpad
  end

  users_collection = connection.db().collection("users")
  existing_user = users_collection.find_one({device_identifier: device_identifier})
  if existing_user then
    # Update
    users_collection.update({_id: existing_user["_id"]}, {"$set" => {push_token: push_token}})
    logger.info "Emu: push token updated for user id " + existing_user["_id"].to_s
  else
    # Create
    user_id = BSON::ObjectId.new
    user = { _id: user_id, device_identifier: device_identifier, device_name: device_name, push_token: push_token }
    users_collection.save(user)

    logger.info "Emu: new user saved in the DB with user id " + user_id.to_s
  end
end


protect do
  post '/emuapi/package' do
    #  get params 

    name = params[:name]
    first_published_on = params[:first_published_on]
    notification_text = params[:notification_text]
    label = params[:label]
    duration = params[:duration]
    frames_count = params[:frames_count]
    thumbnail_frame_index = params[:thumbnail_frame_index]
    source_user_layer_mask = params[:source_user_layer_mask]
    active = params[:active]
    dev_only = params[:dev_only]
    icon_2x = params[:icon_2x]
    icon_3x = params[:icon_3x]

    # upload to s3 and save to mongo
    success = createNewPackage(settings.emu_scratchpad, settings.emu_s3_test, name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icon_2x,icon_3x,first_published_on, notification_text)
    
    result = Hash.new
    result['error'] = success

    return result.to_json
  end
end

protect do
  put '/emuapi/package' do
    #  get params 

    name = params[:name]
    first_published_on = params[:first_published_on]
    notification_text = params[:notification_text]
    label = params[:label]
    duration = params[:duration]
    frames_count = params[:frames_count]
    thumbnail_frame_index = params[:thumbnail_frame_index]
    source_user_layer_mask = params[:source_user_layer_mask]
    removesource_user_layer_mask = params[:removesource_user_layer_mask]
    active = params[:active]
    dev_only = params[:dev_only]
    icon_2x = params[:icon_2x]
    icon_3x = params[:icon_3x]
    country_code = params[:country_code]
    blocked_country_code = params[:blocked_country_code]

    # upload to s3 and save to mongo
    success = updatePackage(
      settings.emu_scratchpad, 
      settings.emu_s3_test, 
      name,
      label,
      duration,
      frames_count,
      thumbnail_frame_index,
      source_user_layer_mask,
      removesource_user_layer_mask,
      active,
      dev_only,
      icon_2x,
      icon_3x,
      first_published_on, 
      notification_text,
      country_code,
      blocked_country_code
      )
    
    result = Hash.new
    result['error'] = success

    return result.to_json
  end
end

protect do
  post '/emuapi/emuticon' do
    #  get params
    package_name = params[:package_name]
    name = params[:name]
    source_back_layer = params[:source_back_layer]
    source_front_layer = params[:source_front_layer]
    source_user_layer_mask = params[:source_user_layer_mask]
    duration = params[:duration]
    frames_count = params[:frames_count]
    thumbnail_frame_index = params[:thumbnail_frame_index]
    palette = params[:palette]
    tags = params[:tags]
    use_for_preview = params[:use_for_preview]

    # upload to s3 and save to mongo
    success = addEmuticon(settings.emu_scratchpad, settings.emu_s3_test, package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,duration,frames_count,thumbnail_frame_index,palette,tags,use_for_preview)
    
    result = Hash.new
    result['error'] = success

    return result.to_json
  end
end

protect do
  put '/emuapi/emuticon' do
    #  get params
    package_name = params[:package_name]
    name = params[:name]
    source_back_layer = params[:source_back_layer]
    source_front_layer = params[:source_front_layer]
    source_user_layer_mask = params[:source_user_layer_mask]
    removesource_back_layer = params[:removesource_back_layer]
    removesource_front_layer = params[:removesource_front_layer]
    removesource_user_layer_mask = params[:removesource_user_layer_mask]
    duration = params[:duration]
    frames_count = params[:frames_count]
    thumbnail_frame_index = params[:thumbnail_frame_index]
    palette = params[:palette]
    tags = params[:tags]
    use_for_preview = params[:use_for_preview]

    # upload to s3 and save to mongo
    success = updateEmuticon(settings.emu_scratchpad, settings.emu_s3_test, package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,removesource_back_layer,removesource_front_layer,removesource_user_layer_mask,duration,frames_count,thumbnail_frame_index,palette,tags,use_for_preview)
    
    result = Hash.new
    result['error'] = success

    return result.to_json
  end
end


def oops_404
  halt 404, "404 - Not found."
end


def oops_500
  halt 500, "500 - Internal server error"
end

def reportToEmuMixpanel(event_name,info={}, distinct_id)
  begin
    puts distinct_id.to_s, event_name, info
    settings.emumixpanel.track(distinct_id.to_s, event_name, info) if settings.respond_to?(:emumixpanel)
  rescue => error
    logger.error "mixpanel error: " + error.to_s
  end
end