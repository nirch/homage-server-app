require 'mongo'
require 'date'
require 'time'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
db = prod_db

remakes_collection = db.collection("Remakes")
sessions_collection = db.collection("Sessions")
users_collection = db.collection("Users")

NUM_OF_USERS_THRESHOLD = 10

launch_date = Time.parse("20140430Z")

grouped_users_by_sessions = sessions_collection.aggregate(
	[
		#{ "$match" => {"status" => {"$in" => [3, 5]} } },
		{ "$group" => {"_id" => {"user_id" => "$user_id"}, "sessions" => {"$sum" => 1} } },
		{ "$sort" => {"sessions" => -1} }
	]
)

#puts grouped_users_by_remakes.count

grouped_users_by_sessions[0..NUM_OF_USERS_THRESHOLD].each do |user_by_sessions|
	user_id = user_by_sessions["_id"]["user_id"]
	user = users_collection.find_one(user_id)

	if !user
		puts "User Id: " + user_id.to_s + " doesn't exist"
		puts
		next
	end

	puts "User Id: " + user_id.to_s
	puts "Sessions: " + user_by_sessions["sessions"].to_s
	if user["email"]
		if user["facebook"]
			puts "User Name: " + user["facebook"]["name"]
		end
		puts "User email: " + user["email"]
	else
		puts "User is guest"
	end

	puts  
end
