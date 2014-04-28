require 'mongo'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
users = test_db.collection("Users")
remakes = test_db.collection("Remakes")

# prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
# prod_users = prod_db.collection("Users")
# prod_remakes = prod_db.collection("Remakes")


remake_id = BSON::ObjectId.from_string("535e4010d6c4ec273f000243")
#x = remakes.update({_id: remake_id}, {"$set" => {status: 3, render_start: Time.now}})
#x = remakes.update({_id: remake_id}, {"$set" => {status: 3, render_end: Time.now}})
remake = remakes.find_one(remake_id)
x = Time.now - remake["render_start"]
puts x


# start_date = Time.now
# sleep 10
# end_date = Time.now
# delta_date = end_date - start_date
# puts delta_date

# date = Time.utc(2014,4,22)
# x = remakes.find({"created_at" => {"$gte" => date}, "status" => 3})
# for remake in x do
# 	puts remake["share_link"]
# end


# DIVE_SCHOOL = BSON::ObjectId.from_string("52de83db8bc427751c000305") # Dive School
# x = remakes.count({query: {story_id: DIVE_SCHOOL, status: 3}})
# puts x


# remake_id = BSON::ObjectId.from_string("533312f9f52d5c1ec2000020")
# user_id = BSON::ObjectId.from_string("5333eeb6f52d5c3ae5000004")
# report = {reported_at: Time.now, user_id: user_id}
# response = remakes.update({_id: remake_id}, {"$push" => {reports: report}})
# puts response

# date = Time.utc(2014,3,23)
# delete_users = users.find({"created_at" => {"$gte" => date}})

# for delete_user in delete_users
# 	users.remove({_id: delete_user["_id"]})
# end



# good_remakes = prod_remakes.find({demo:true})
# for remake in good_remakes do
# 	user_exist = prod_users.find_one({_id:remake["user_id"]})
# 	if !user_exist then
# 		puts remake["_id"].to_s + "; " + remake["user_id"]
# 	end
# end




# #### Copy Remakes from Test to Prod

# remakes_to_copy = remakes.find({demo:true})
# puts "Good remakes = " + remakes_to_copy.count.to_s
# prod_remakes = prod_db.collection("Remakes")

# count = 0

# for remake in remakes_to_copy do
# 	remake_exist = prod_remakes.find_one(remake["_id"])
# 	if !remake_exist then
# 		count += 1
# 		result = prod_remakes.save(remake) 
# 		puts result
# 	end
# end

# puts "Remakes to copy = " + count.to_s


# #### Public Remakes #################################

# public_users_cursor = users.find({is_public:true})
# public_users = Array.new

# for user in public_users_cursor do
# 	public_users.push(user["_id"])
# end

# all_remakes = remakes.find({story_id: BSON::ObjectId.from_string("52de83db8bc427751c000305"), status:3})
# puts "All remakes = " + all_remakes.count.to_s

# yoav_remakes = remakes.find({story_id: BSON::ObjectId.from_string("52de83db8bc427751c000305"), status:3, user_id:"yoav@homage.it"})
# puts "Yoav remakes = " + yoav_remakes.count.to_s

# public_remakes = remakes.find({story_id: BSON::ObjectId.from_string("52de83db8bc427751c000305"), status:3, user_id:{"$in" => public_users}})
# puts "Public remakes = " + public_remakes.count.to_s

#######################################################

#story_id = BSON::ObjectId.from_string("52de83db8bc427751c000305")
