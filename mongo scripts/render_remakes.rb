require 'uri'
require 'net/http'
require 'mongo'

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")


prod_render = URI.parse("http://homage-server-app-prod.elasticbeanstalk.com/render")
test_render = URI.parse("http://homage-server-app-dev.elasticbeanstalk.com/render")

render_remakes = [
"5430e3ed0be0443f8600000a", 
"5430e44f0be0443f8600000b", 
"5430e5f30be0443f8600000f", 
"5430e67b0be0443f86000010", 
"5430e6dd0be0443f86000011", 
"5430e73e0be0443f86000013", 
"5430e7a40be0443f86000014", 
"5430e80e0be0444456000001", 
"5430ebba0be0443f86000017", 
"54322a1b0be0447060000001", 
"54322a630be0447060000003", 
"543232fe0be04463b4000006", 
]


for remake_id in render_remakes do
	remake = prod_remakes.find_one(BSON::ObjectId.from_string(remake_id))
	puts "remake: " + remake["_id"].to_s + "; status = " + remake["status"].to_s

	# response = Net::HTTP.post_form(prod_render, {"remake_id" => remake_id.to_s})
	# puts response
end
