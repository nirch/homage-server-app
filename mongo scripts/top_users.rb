require 'mongo'
require 'date'
require 'time'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
db = prod_db

remakes_collection = db.collection("Remakes")
users_collection = db.collection("Users")

NUM_OF_REMAKES_THRESHOLD = 10

launch_date = Time.parse("20140430Z")

grouped_users_by_remakes = remakes_collection.aggregate(
	[
		{ "$match" => {"status" => {"$in" => [3, 5]} } },
		{ "$group" => {"_id" => {"user_id" => "$user_id"}, "remakes" => {"$sum" => 1} } },
		{ "$sort" => {"remakes" => -1} }
	]
)

#puts grouped_users_by_remakes.count

grouped_users_by_remakes[0..NUM_OF_REMAKES_THRESHOLD].each do |user_by_remakes|
	user_id = user_by_remakes["_id"]["user_id"]
	user = users_collection.find_one(user_id)

	puts "User Id: " + user_id.to_s
	puts "Remakes: " + user_by_remakes["remakes"].to_s
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


# counter = 0

# # Getting all the top users
# all_users = PROD_USERS.find(created_at:{"$gte"=>launch_date})
# engaged_users = Hash.new
# no_email_engaged_users = 0
# for user in all_users do
# 	remakes_for_user = PROD_REMAKES.find(user_id:user["_id"], status:{"$in"=>[3,5]}, share_link:{"$exists"=>1}).count
# 	if remakes_for_user >= NUM_OF_REMAKES_THRESHOLD then
# 		if user["email"]
# 			engaged_users[user["_id"].to_s] = remakes_for_user
# 		else
# 			++no_email_engaged_users
# 		end
# 	end

# 	if counter >= 50 then
# 		break
# 	end
# 	counter += 1
# end

# puts engaged_users.count.to_s + " users, created " + NUM_OF_REMAKES_THRESHOLD.to_s + " or more (and have an email)"
# puts no_email_engaged_users.to_s + " users, created " + NUM_OF_REMAKES_THRESHOLD.to_s + " or more but don't have an email..."

# # Sorting by the most engaged user on top
# sorted_users = engaged_users.sort_by {|k,v| v}.reverse

# for sorted_user in sorted_users do
# 	puts sorted_user
# end

# # for user in engaged_users do
# # 	puts user
# # end