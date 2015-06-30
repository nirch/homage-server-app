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
"559179cacbffc2102300000d", 
"559178d8eeb909093b000007", 
"559163e9cbffc21023000003", 
"55917ce5eeb9091695000003", 
"559122deeeb90903ed00000e", 
"559174f1eeb909093b000003", 
"5590dce1cbffc22cff000006", 
"559178d5cbffc2102300000b", 
"5591ce0dcbffc22bd2000003", 
"5591f528eeb9095f93000005", 
"55917d88eeb90918aa000002", 
"5591ec96cbffc232fb000002", 
"5591cb4feeb9095c7b000001", 
"55918426eeb90918aa000004", 
"5591f77beeb90973ba000001", 
"55847d5aeeb90959b2000005", 
"55920379cbffc24725000002", 
"5591c9b0eeb90918aa000007", 
"559177f2eeb909093b000006", 
"55921c32cbffc24725000004", 
"55916c49cbffc21023000006", 
"5591d011eeb9095f93000001", 
"55916c9fcbffc21023000008", 
"5591ce1beeb9095c7b000002", 
"559162facbffc21023000002", 
"5591743beeb909093b000002", 
"5591f432eeb9095f93000004", 
"55915f61eeb9090828000004", 
"5590e868cbffc22cff000007", 
"55920634eeb9095f93000007", 
"55917d60eeb90918aa000001", 
"55916c21cbffc21023000005", 
"559277a8eeb9092413000001", 
"55915da6eeb9090828000001", 
"5591872ecbffc2102300000f", 
"559205d2cbffc24725000003", 
"559204d6eeb9095f93000006"
]


for remake_id in render_remakes do
	remake = prod_remakes.find_one(BSON::ObjectId.from_string(remake_id))
	puts "remake: " + remake["_id"].to_s + "; status = " + remake["status"].to_s

	# response = Net::HTTP.post_form(prod_render, {"remake_id" => remake_id.to_s})
	# puts response
end
