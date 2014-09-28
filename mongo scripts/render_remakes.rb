require 'uri'
require 'net/http'
require 'mongo'

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")


prod_render = URI.parse("http://homage-server-app-prod.elasticbeanstalk.com/render")
test_render = URI.parse("http://homage-server-app-dev.elasticbeanstalk.com/render")

render_remakes = [
"542302450be04460b2000009",
"542317380be0447d87000001",
"54231a8a0be0447d87000005",
"54231d4d0be0447d87000006",
"54233f9b0be0447d8700000c",
"542345120be0447d8700000e",
"5423455e0be0447d87000011",
"5423455c0be0447d87000010",
"5423497e0be04417c9000001",
"54234bf70be04417c9000002",
"54234ccd0be04417c9000003",
"542355900be0441fa2000001",
"54236b450be0441fa2000005",
"54236bd40be0441fa2000006",
"54236c9a0be0442ad3000002",
"54236e4e0be0442ad3000005",
"54236e4e0be0442ad3000004",
"54236fa90be0442ad3000006",
"542373390be0442f58000001",
"542374540be0442ad3000008",
"542376e10be0442ad3000009",
"54238c230be0443257000002",
"5423b8e10be044543e000001",
"5423bb350be044543e000003",
"5423bbca0be044543e000004",
"5423bc1a0be044571d000001",
"5423d07b0be0446250000001",
"5423e3e10be0446250000003",
"5423e4420be0446250000004"
]


for remake_id in render_remakes do
	remake = prod_remakes.find_one(BSON::ObjectId.from_string(remake_id))
	puts "remake: " + remake["_id"].to_s + "; status = " + remake["status"].to_s

	# response = Net::HTTP.post_form(prod_render, {"remake_id" => remake_id.to_s})
	# puts response
end
