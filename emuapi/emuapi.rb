#encoding: utf-8
require_relative 'emuapi_config'
require_relative '../emuconsole/logic/package'


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
  config = settings.emu_db.collection("config").find({"client_name"=>"Emu iOS"}).to_a
  if (config.count != 1)
    return oops_500
  end
  config = config.to_a[0]

  # Get the packages
  packages = settings.emu_db.collection("packages").find({}, {:fields=>fields_projection})
  packages = packages.to_a

  # Also include the config information with the result
  result = Hash.new
  result = result.merge(config)
  result["packages_count"] = packages.count
  result["packages"] = packages
  return result.to_json()
end

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
  icons_files_list_html = params[:icons_files_list]
  icons_files_list = parseIconsFilesListToJson(icons_files_list_html)

  # upload to s3 and save to mongo
  createNewPackage(first_published_on,last_update,name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icons_files_list)
  "finito bambino"
end

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
  icons_files_list_html = params[:icons_files_list]
  icons_files_list = parseIconsFilesListToJson(icons_files_list_html)

  # upload to s3 and save to mongo
  updatePackage(first_published_on,last_update,name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icons_files_list)
  "finito bambino"
end

def parseIconsFilesListToJson(icons_files_list_html)

  icons_files_list = []

  list_icon_files = icons_files_list_html.split('|')

  for filename in list_icon_files do
    icon_hash = Hash.new
    icon_hash["filename"] = filename
    icon_hash["filepath"] = "/Users/dangal/Downloads/server/" + filename
    icons_files_list << icon_hash
  end

  return icons_files_list

end


def oops_404
  return "oops... 404 error."
end


def oops_500
  return "oops... 500 internal server error."
end