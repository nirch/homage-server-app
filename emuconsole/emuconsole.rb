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

	createNewPackage(nil,Time.now,"aligator","hamat",24,23,3,nil,false,true,icons_files_list)

	puts "emoticon updated"

  	"<br>End Activity"
end

get '/emuconsole/display' do
	erb :emuconsole
end

def upload_file(local_file_path, server_file_path)
	@filename = server_file_path
	file = File.open(local_file_path, 'r')
 
  	File.open("/Users/dangal/Downloads/server/#{@filename}", 'wb') do |f|
    	f.write(file.read)
  	end
end