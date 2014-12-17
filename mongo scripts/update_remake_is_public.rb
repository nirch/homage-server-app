require 'mongo'
require 'date'
require 'time'
require 'aws-sdk'
require 'open-uri'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
db = test_db

users_collection = db.collection("Users")
remakes_collection = db.collection("Remakes")
stories_collection = db.collection("Stories")

# Getting all the users
launch_date = Time.parse("20140430Z")
all_users = users_collection.find(created_at:{"$gte"=>launch_date}, is_public:{"$exists"=>true})

for user in all_users do
	# Update all the remakes for the current user as public/private
	result = remakes_collection.update({user_id:user["_id"]}, {"$set" => {is_public: user["is_public"]}}, {multi:true})
	puts result
end