require 'uri'
require 'net/http'
require 'mongo'

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
test_users = test_db.collection("Users")
test_remakes = test_db.collection("Remakes")



prod_render = URI.parse("http://homage-server-app-prod.elasticbeanstalk.com/render")
test_render = URI.parse("http://homage-server-app-dev.elasticbeanstalk.com/render")

render_remakes = [
"546a05110be04468ce000003", 
"546a05510be04468ce000004", 
#"546a05ef0be04468ce000005", 
#"546a07820be04468ce000006", 
]


for remake_id in render_remakes do
	remake = prod_remakes.find_one(BSON::ObjectId.from_string(remake_id))
	puts "remake: " + remake["_id"].to_s + "; status = " + remake["status"].to_s

	#response = Net::HTTP.post_form(prod_render, {"remake_id" => remake_id.to_s})
	#puts response
end
