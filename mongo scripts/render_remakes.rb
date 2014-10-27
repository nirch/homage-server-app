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
"5448fd94771ac15b9a000001", 
]


for remake_id in render_remakes do
	remake = test_remakes.find_one(BSON::ObjectId.from_string(remake_id))
	puts "remake: " + remake["_id"].to_s + "; status = " + remake["status"].to_s

	# response = Net::HTTP.post_form(test_render, {"remake_id" => remake_id.to_s})
	# puts response
end
