#encoding: utf-8
require_relative 'emuapi_config'
require_relative 'emuapi_sampled_content'
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

get '/emu/iosstore' do
  shared_from = params[:src]

  info = Hash.new
  info["shared_from"] = shared_from
  reportToEmuMixpanel("LandingPageIosStoreLink",info)
  redirect 'https://itunes.apple.com/app/id969789079', 302
end

# get '/test/bson' do
#   packages = settings.emu_test.db().collection("packages").find({})
#   packages.to_json
#   # for package in packages do
#   #   x = package.to_json
#   #   puts package["_id"].class
#   #   break
#   # end
#   # x
# end

# post '/dan/test' do
#   name = MongoMapper.connection.name
#   "name of current db = " + name.to_s
# end

# just for testing.
# GET route - test
# get '/emuapi/test' do
#   "Hello emu world! The time is " + Time.now.strftime("%d/%m/%Y %H:%M:%S")
# end


# GET all available packages info
# :verbosity -
#   full - the result will also include all emuticons information for every package
#   metadata - the result will only include meta data about the packages (excluding emuticons info)
get '/emuapi/packages/:verbosity' do

  # determine the verbosity of the result
  connection = settings.emu_public
  use_scratchpad = request.env['HTTP_SCRATCHPAD'].to_s
  if use_scratchpad == "true"
    connection = settings.emu_scratchpad
  end

  verbosity = params[:verbosity]
  case verbosity
    when "meta"
      fields_projection = {"emuticons"=>false}
    when "full"
      fields_projection = nil
    else
      return oops_404
  end

  # Get the config information
  config = connection.db().collection("config").find({"config_type"=> "app config", "client_name"=>"Emu iOS"}).to_a
  if (config.count != 1)
    return oops_500
  end
  config = config.to_a[0]

  # Handle sampled user content
  already_sampled_header = request.env['HTTP_USER_SAMPLED_BY_SERVER'].to_s
  already_sampled = already_sampled_header=="true"
  handle_upload_user_content(config, connection, already_sampled=already_sampled)

  # Get the packages
  packages = connection.db().collection("packages").find({}, {:fields=>fields_projection})
  packages = packages.to_a

  # Also include the config information with the result
  result = Hash.new
  result = result.merge(config)
  result["packages_count"] = packages.count
  result["packages"] = packages
  return result.to_json()
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

    # upload to s3 and save to mongo
    success = updatePackage(settings.emu_scratchpad, settings.emu_s3_test, name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,removesource_user_layer_mask,active,dev_only,icon_2x,icon_3x,first_published_on, notification_text)
    
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
  return "oops... 404 error."
end


def oops_500
  return "oops... 500 internal server error."
end

def reportToEmuMixpanel(event_name,info={})
  begin
    settings.emumixpanel.track("12345", event_name, info) if settings.respond_to?(:emumixpanel)
  rescue => error
    logger.error "mixpanel error: " + error.to_s
  end
end