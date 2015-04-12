require_relative '../emuapi/emuapi_config'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require 'byebug'

# test
get '/emuconsole/test' do
	'Start Activity<br>'

	upload_file("/Users/dangal/Downloads/party_icon@3x.png", "party_icon@3x.png")
	upload_file("/Users/dangal/Downloads/party_icon@2x.png", "party_icon@2x.png")
	icons_files_list = [{"filename" => "party_icon@2x.png","filepath" => "/Users/dangal/Downloads/server/party_icon@2x.png"},
						{"filename" => "party_icon@3x.png","filepath" => "/Users/dangal/Downloads/server/party_icon@3x.png"}]

	# createNewPackage(nil,Time.now,"aligator","al barbur",25,23,3,nil,false,true,icons_files_list)
	createNewPackage(nil,nil,"aligator",nil,25,nil,nil,nil,false,true,nil)

	# upload_file("/Users/dangal/Downloads/party_icon@3x.png", "party_icon@3x.png")
	# upload_file("/Users/dangal/Downloads/party_icon@2x.png", "party_icon@2x.png")

	# addEmuticon(getPackageIDByName("aligator"),"crocs","celebration-bg.gif","/Users/dangal/Downloads/celebration-bg.gif","celebration-fg.gif","/Users/dangal/Downloads/celebration-fg.gif",nil,nil,nil,nil,"croc",false)

	puts "emoticon updated"

  	"<br>End Activity"
end

get '/emuconsole/display' do
	@packs_scratchpad = get_all_packages(settings.emu_scrathpad)
	@packs_public = get_all_packages(settings.emu_public)
	erb :emuconsole
end

get '/emuconsole/upload' do
	puts "*********************"
	puts params
	puts "*********************"
	# upload_file
end

def upload_file(local_file_path, server_file_path)
	@filename = server_file_path
	file = File.open(local_file_path, 'r')
 
  	File.open("/Users/dangal/Downloads/server/#{@filename}", 'wb') do |f|
    	f.write(file.read)
  	end
end