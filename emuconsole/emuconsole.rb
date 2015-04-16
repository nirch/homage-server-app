require_relative '../emuapi/emuapi_config'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require_relative 'emuzipper'
require_relative 'emudeployer'

# test
# get '/emuconsole/test' do
# 	testhelper
# end

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

protect do
	get '/emuconsole/display' do
		@awspackageslink = "https://homage-emu-dev-test.s3.amazonaws.com/packages/"
		if(settings.enviornment == "production")
			@awspackageslink = "https://homage-emu-test.s3.amazonaws.com/packages/"
		end
		@packs_scratchpad = get_all_packages(settings.emu_scratchpad)
		@packs_public = get_all_packages(settings.emu_public)
		erb :emuconsole
	end
end


get '/emuconsole/test' do
	packs_scratchpad = get_all_packages(settings.emu_scratchpad)
	return packs_scratchpad.to_json
end

protect do
	post '/emuconsole/zip' do
		package_name = params[:package_name]
		zipEmuPackage(package_name)
	end
end

protect do
	post '/emuconsole/deploy' do
		package_name = params[:package_name]
		deployEmuPackage(package_name)
	end
end

def upload_file(local_file_path, server_file_path)
	@filename = server_file_path
	file = File.open(local_file_path, 'r')
 
  	File.open("/Users/dangal/Downloads/server/#{@filename}", 'wb') do |f|
    	f.write(file.read)
  	end
end