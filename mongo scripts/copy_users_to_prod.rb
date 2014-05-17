require 'mongo'


prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db

prod_users = prod_db.collection("Users")
test_users = test_db.collection("Users")

users_to_copy = Set.new [BSON::ObjectId.from_string("536d547ff52d5c7765000002"),
BSON::ObjectId.from_string("536d555cf52d5c7765000003"),
BSON::ObjectId.from_string("536d6022f52d5c7765000005"),
BSON::ObjectId.from_string("536d80f1f52d5c776500000a"),
BSON::ObjectId.from_string("536d86a8f52d5c776500000b"),
BSON::ObjectId.from_string("536d9322f52d5c776500000d"),
BSON::ObjectId.from_string("536db8e5f52d5c7765000010"),
BSON::ObjectId.from_string("536dc708f52d5c7765000018"),
BSON::ObjectId.from_string("536dcfc5f52d5c776500001a"),
BSON::ObjectId.from_string("536dd264f52d5c776500001c"),
BSON::ObjectId.from_string("536dda3ff52d5c776500001f"),
BSON::ObjectId.from_string("536ddda7f52d5c7765000021"),
BSON::ObjectId.from_string("536de1b8f52d5c7765000026"),
BSON::ObjectId.from_string("536de9e5f52d5c776500002e"),
BSON::ObjectId.from_string("536e04e3f52d5c7765000033"),
BSON::ObjectId.from_string("536e117ff52d5c7765000037"),
BSON::ObjectId.from_string("536e18baf52d5c776500003b")]

for user_id in users_to_copy do
	# Getting the user from test to copy
	user_to_copy = test_users.find_one({_id: user_id})

	# Updating/Creating the story in production
	result = prod_users.update({_id: user_id}, user_to_copy, {upsert: true})
	puts " copy to prod result = " + result.to_s
end
