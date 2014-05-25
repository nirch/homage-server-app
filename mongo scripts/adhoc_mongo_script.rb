require 'mongo'
require 'date'
require 'time'
require 'aws-sdk'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
users = test_db.collection("Users")
remakes = test_db.collection("Remakes")

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")


# date_input = "20140509"
# from_date = Time.parse(date_input)
# unique_users = Set.new
# users_from_date = users.find(created_at:{"$gte"=>from_date})
# remakes_from_date = prod_remakes.find(created_at:{"$gte"=>from_date})
# puts users_from_date.count
# puts remakes_from_date.count
# for user in users_from_date do
# 	unique_users.add(user["_id"])
# end
# for remake in remakes_from_date do
# 	unique_users.add(remake["user_id"])
# end
# puts unique_users.count
# for user_id in unique_users do
# 	user = prod_users.find_one(user_id)
# 	if user then
# 		if user["email"] then
# 			if user["facebook"] then
# 				puts user["facebook"]["name"] + " - " + user["email"] 
# 			else
# 				puts user["email"]
# 			end
# 		else
# 			#puts user_id.to_s + " has no email"
# 		end
# 	else
# 		puts user_id.to_s + " doensn't exist"
# 	end
# end

# # AWS Connection
# aws_config = {access_key_id: "AKIAJTPGKC25LGKJUCTA", secret_access_key: "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"}
# AWS.config(aws_config)
# s3 = AWS::S3.new
# s3_bucket = s3.buckets['homageapp']

# date_input = "20140518"
# from_date = Time.parse(date_input)
# unfinished_remakes = prod_remakes.find(created_at:{"$gte"=>from_date}, status:4)
# puts "unfinished_remakes = " + unfinished_remakes.count.to_s
# for remake in unfinished_remakes do
# 	raw_scene_prefix = "Remakes/" + remake["_id"].to_s + "/raw_scene"
# 	s3_objects = s3_bucket.objects.with_prefix(raw_scene_prefix)

# 	if s3_objects.count == remake["footages"].count then
# 		puts remake["_id"].to_s + " All scenes uploaded!!!"

# 		processed_scene_prefix = "Remakes/" + remake["_id"].to_s + "/processed_scene"
# 		s3_processed_objects = s3_bucket.objects.with_prefix(processed_scene_prefix)
# 		if s3_processed_objects.count == remake["footages"].count then
# 			puts "All scenes processed!!!"
# 		else
# 			puts "Not all scenes processed..."
# 		end
# 	else
# 		puts remake["_id"].to_s + " not ready... only " + s3_objects.count.to_s + " out of " + remake["footages"].count.to_s
# 	end
# 	#s3_object = bucket.objects[s3_key]
# end


# for remake in remakes_from_date do
# 	user_in_prod = prod_users.find_one(remake["user_id"])

# 	if user_in_prod then
# 		puts "Prod! for remake " + remake["_id"].to_s
# 	else
# 		puts "Not prod! for remake " + remake["_id"].to_s
# 	end
# end

# date_input = "20140509"
# from_date = Time.parse(date_input)
# users_from_date = users.find(created_at:{"$gte"=>from_date})
# puts users_from_date.count.to_s
# for user in users_from_date do
# 	user_in_prod = prod_users.find_one(user["_id"])
# 	if user_in_prod then
# 		puts "Prod! " + user["_id"].to_s
# 	else
# 		puts user["_id"].to_s
# 	end
# end

# date_input = "20140430"
# from_date = Time.parse(date_input)
# remakes_from_date = prod_remakes.find(created_at:{"$gte"=>from_date}, status:3).sort(created_at:1)
# puts remakes_from_date.count.to_s + " Remakes from " + from_date.strftime("%d/%m/%Y")
# puts remakes_from_date.count


# remake_id = BSON::ObjectId.from_string("535e4010d6c4ec273f000243")
# #x = remakes.update({_id: remake_id}, {"$set" => {status: 3, render_start: Time.now}})
# #x = remakes.update({_id: remake_id}, {"$set" => {status: 3, render_end: Time.now}})
# remake = remakes.find_one(remake_id)
# x = Time.now - remake["render_start"]
# puts x


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
