#encoding: utf-8
require_relative 'emuapi_config'
require_relative '../emuconsole/logic/package'
require 'byebug'

before do
  use_scratchpad = request.env['HTTP_SCRATCHPAD'].to_s
  if use_scratchpad == "true" and MongoMapper.connection.db().name != settings.emu_scrathpad.db().name then
    MongoMapper.connection = settings.emu_scrathpad
    MongoMapper.database = settings.emu_scrathpad.db().name
  elsif use_scratchpad != "true"  and MongoMapper.connection.db().name != settings.emu_public.db().name then
    MongoMapper.connection = settings.emu_public
    MongoMapper.database = settings.emu_public.db().name
  end
  # else public
end

post '/dan/test' do
  name = MongoMapper.connection.name
  "name of current db = " + name.to_s
end

# just for testing.
# GET route - test
get '/emuapi/test' do
  "Hello emu world! The time is " + Time.now.strftime("%d/%m/%Y %H:%M:%S")
end


# GET all available packages info
# :verbosity -
#   full - the result will also include all emuticons information for every package
#   metadata - the result will only include meta data about the packages (excluding emuticons info)
get '/emuapi/packages/:verbosity' do
  # determine the verbosity of the result
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
  config = settings.emu_public.db().collection("config").find({"client_name"=>"Emu iOS"}).to_a
  if (config.count != 1)
    return oops_500
  end
  config = config.to_a[0]

  # Get the packages
  packages = settings.emu_public.db().collection("packages").find({}, {:fields=>fields_projection})
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

    first_published_on = params[:first_published_on]
    if(first_published_on) != nil
      first_published_on = Time.now
    end
    last_update = params[:last_update]
    if(last_update) != nil
      last_update = Time.now
    end
    name = params[:name]
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
    createNewPackage(first_published_on,last_update,name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icon_2x,icon_3x)
    "finito bambino"
  end
end

protect do
  put '/emuapi/package' do
    #  get params 
    
    first_published_on = params[:first_published_on]
    if(first_published_on) != nil
      first_published_on = Time.now
    end
    last_update = params[:last_update]
    if(last_update) != nil
      last_update = Time.now
    end
    name = params[:name]
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
    updatePackage(first_published_on,last_update,name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icon_2x,icon_3x)
    "finito bambino"
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
    palette = params[:palette]
    patched_on = params[:patched_on]
    tags = params[:tags]
    use_for_preview = params[:use_for_preview]

    # upload to s3 and save to mongo
    addEmuticon(package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,palette,patched_on,tags,use_for_preview)
    "finito bambino"
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
    palette = params[:palette]
    patched_on = params[:patched_on]
    tags = params[:tags]
    use_for_preview = params[:use_for_preview]

    # upload to s3 and save to mongo
    updateEmuticon(package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,palette,patched_on,tags,use_for_preview)
    "finito bambino"
  end
end


def oops_404
  return "oops... 404 error."
end


def oops_500
  return "oops... 500 internal server error."
end