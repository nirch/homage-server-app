require_relative '../emuapi/emuapi_config'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require_relative 'emuzipper'
require 'byebug'

# test
# get '/emuconsole/test' do
# 	testhelper
# end

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

protect do
	get '/emuconsole/display' do

		@packs_scratchpad = get_all_packages(settings.emu_scrathpad)
		@packs_public = get_all_packages(settings.emu_public)
		erb :emuconsole
	end
end

protect do
	post '/emuconsole/zip' do
		package_name = params[:package_name]
		zipEmuPackage(package_name)
	end
end

def upload_file(local_file_path, server_file_path)
	@filename = server_file_path
	file = File.open(local_file_path, 'r')
 
  	File.open("/Users/dangal/Downloads/server/#{@filename}", 'wb') do |f|
    	f.write(file.read)
  	end
end