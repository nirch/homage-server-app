require 'mongo'
require 'date'
require 'time'
require 'logger' 


test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db

db = prod_db

users = db.collection("Users")
remakes = db.collection("Remakes")
stories = db.collection("Stories")

campaign_id = BSON::ObjectId.from_string("544ead1e454c610d1600000f")

stories_array = stories.find({active:true, campaign_id: campaign_id})
puts stories_array.count


for story in stories_array do
	puts story["_id"].to_s + " " + story["name"] + " " + story["sharing_video_allowed"].to_s

	# stories.update({ _id: story["_id"] },{"$set" => {sharing_video_allowed: false}})

end