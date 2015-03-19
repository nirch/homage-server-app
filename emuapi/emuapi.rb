#encoding: utf-8
require_relative 'emuapi_config'


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


def oops_404
  return "oops... 404 error."
end


def oops_500
  return "oops... 500 internal server error."
end