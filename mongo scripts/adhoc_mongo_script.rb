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

remakes = ["53ecdebe0be0440cdc000009","53ee5f2f0be0445d5d00000b","53ee10210be0443520000008","53ee6d690be0446c45000006","53ee820f0be0447547000009","53ee91a90be044754700001e","53ef08270be0443897000015","53ef61560be0447457000003","53efbd5a0be04428b9000004","53f018a80be0445c23000008","53f0b3480be044333e00000d","53f0fe0b0be0445ecc000001","53f128290be0447785000001","53f1e5500be0445cff000003","53f20ac20be044732b000007","53f222480be04475b8000014","53f2ee050be0447036000001","53f3521d0be0442536000008","53f3d4250be04469b6000011","53f4b4a30be04468aa000002","53f4db890be0447c81000008","53f4ebf60be0440625000003","53f510ee0be0441c67000002","53f525dc0be0441f7c00000b","53f541030be04433c0000001","53f608300be0441f65000002","53f6c24e0be0447cfc000005","53f6a7f60be04474e3000003","53f751dd0be0445511000001","53f76d190be0445511000008","53f7bf230be0440444000006","53f7f0ac0be044238c000005","53f87e5b0be044495c00000b","53f8803b0be044772d000001","53f891c60be0447ee5000006","53f8aec70be0440ae0000008","53f8e7fb0be0442ecf000002","53f8fe320be04439db000005","53f930340be044569a000001","53f999cc0be0440b50000007","53f99b1f0be0440b50000008","53f9f3d70be04416f8000018","53fa1bbd0be0445662000001","53fa73a90be0440355000007","53fa8c420be0440b15000005","53fa9da80be0441d81000005","53fab8610be044202a000014"]
puts remakes.count

for remake_id in remakes do
	remake = prod_remakes.find_one(BSON::ObjectId.from_string(remake_id))
	puts remake_id + ": " + remake["status"].to_s
	# homage_server_uri = URI.parse("http://homage-server-app-prod.elasticbeanstalk.com/render")
	# response = Net::HTTP.post_form(homage_server_uri, {"remake_id" => remake_id.to_s})
	# puts response
end



# from_date = Time.parse("20140814Z")
# superior_man_id = BSON::ObjectId.from_string("535e8fc981360cd22f0003d4")
# monster_attack_id = BSON::ObjectId.from_string("532f058a3f13af9af80001bb")
# stories_with_kness = [superior_man_id, monster_attack_id]
# scene_hash = {monster_attack_id => 3, superior_man_id => 4}
# failed_remakes = prod_remakes.find({story_id: {"$in" => stories_with_kness}, created_at:{"$gte"=>from_date}, status:4})
# puts failed_remakes.count
# print "["
# for failed_remake in failed_remakes do
# 	remake_id = failed_remake["_id"].to_s
# 	story_id = failed_remake["story_id"]
# 	scene_id = scene_hash[story_id]
# 	take_id = failed_remake["footages"][scene_id - 1]["take_id"]
# 	#puts '["' + remake_id + '", ' + '"' + scene_id.to_s + '", "' + take_id + '"],'
# 	print '"' + remake_id + '",'
# end
# puts "]"


# <<<<<<< HEAD
# puts File.dirname(File.expand_path(__FILE__)) + "/logs"
# #puts File.join(File.expand_path(__FILE__), '..', 'logs')
# =======
# great_remakes = prod_remakes.find({story_id: BSON::ObjectId.from_string("535e8fc981360cd22f0003d4"), grade:{"$gte"=>12}})

# for remake in great_remakes do
# 	puts remake["_id"]
# end

# #puts File.stat("/Users/tomer/Desktop/Delete/Old Spice_v01_test.mp4").world_writable?
# >>>>>>> 7f7cdbcd986b326919799dc2439dafe2aa86186d

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
