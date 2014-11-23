require 'mongo'
require 'date'
require 'time'
require 'aws-sdk'
require 'open-uri'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
test_users = test_db.collection("Users")
test_remakes = test_db.collection("Remakes")
test_stories = test_db.collection("Stories")
test_campaigns = test_db.collection("Campaigns")
test_views = test_db.collection("Views")

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")
prod_shares = prod_db.collection("Shares")
prod_sessions = prod_db.collection("Sessions")
prod_stories = prod_db.collection("Stories")
prod_views = prod_db.collection("Views")


grouped_views = prod_views.aggregate([{ "$group" => {"_id" => {"remake_id" => "$remake_id"}, "views" => {"$sum" => 1}} }])

puts grouped_views.count
for remake_views in grouped_views do
	remake_id = remake_views["_id"]["remake_id"]
	views = remake_views["views"]
	
	puts "Updating remake " + remake_id.to_s + " with views: " + views.to_s
	remake = prod_remakes.find_one(remake_id)

	if remake && remake["views"] && remake["views"] > views
		puts "REMAKE HAS MORE VIEWS"
	else
		prod_remakes.update({_id: remake_id}, {"$set" => {views: views}}) if remake
	end
end