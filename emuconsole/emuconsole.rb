require_relative '../emuapi/emuapi_config'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require 'byebug'

# test
get '/emuconsole/test' do
	'Start Activity<br>'
	# addEmuticon(getPackageIDByName("gumba"),"rats","sewer.gif","bats.gif",nil)
	createNewPackage(nil,Time.now,"aligator_name","aligator","hamat",24,nil,3,nil,nil,nil)
	# updateEmuticon(getPackageIDByName("gumba"),"nir","blah",nil,nil)

	puts "emoticon updated"

  	"<br>End Activity"
end

get '/emuconsole/display' do
	erb :emuconsole
end
