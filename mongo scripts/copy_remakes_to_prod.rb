require 'mongo'


prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db

prod_remakes = prod_db.collection("Remakes")
test_remakes = test_db.collection("Remakes")

remakes_to_copy = Set.new [
BSON::ObjectId.from_string("536d66eaf52d5c7765000008"),
BSON::ObjectId.from_string("536dc22ef52d5c7765000015"),
BSON::ObjectId.from_string("536d561af52d5c7765000004"),
BSON::ObjectId.from_string("536de5a9f52d5c7765000028"),
BSON::ObjectId.from_string("536e1f27f52d5c776500003e"),
BSON::ObjectId.from_string("536de87df52d5c776500002c"),
BSON::ObjectId.from_string("536dffd9f52d5c7765000030")
						]

for remake_id in remakes_to_copy do
	# Getting the user from test to copy
	remake_to_copy = test_remakes.find_one({_id: remake_id})

	# Updating/Creating the story in production
	result = prod_remakes.update({_id: remake_id}, remake_to_copy, {upsert: true})
	puts " copy to prod result = " + result.to_s
end
