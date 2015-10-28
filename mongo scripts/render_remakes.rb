require 'uri'
require 'net/http'
require 'mongo'

# prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
# prod_users = prod_db.collection("Users")
# prod_remakes = prod_db.collection("Remakes")

# test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
# test_users = test_db.collection("Users")
# test_remakes = test_db.collection("Remakes")


test_db = Mongo::Client.new(['paulo.mongohq.com:10008'], :database => 'Homage', :user => 'Homage', :password => 'homageIt12', :connect => :direct)
test_users = test_db["Users"]
test_remakes = test_db["Remakes"]

prod_db = Mongo::Client.new(['troup.mongohq.com:10057'], :database => 'Homage_Prod', :user => 'Homage', :password => 'homageIt12', :connect => :direct)
prod_users = prod_db["Users"]
prod_remakes = prod_db["Remakes"]

Mongo::Logger.logger.level = Logger::WARN



prod_render = URI.parse("http://homage-server-app-prod.elasticbeanstalk.com/render")
test_render = URI.parse("http://homage-server-app-dev.elasticbeanstalk.com/render")

render_remakes = [
"562a087e7c67f26a32000002"
]


for remake_id in render_remakes do
	#remake = prod_remakes.find_one(BSON::ObjectId.from_string(remake_id))
	remake = test_remakes.find({_id:BSON::ObjectId.from_string(remake_id)}).each.next
	puts "remake: " + remake["_id"].to_s + "; status = " + remake["status"].to_s

	# response = Net::HTTP.post_form(prod_render, {"remake_id" => remake_id.to_s})
	# puts response
end
