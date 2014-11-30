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

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")
prod_shares = prod_db.collection("Shares")
prod_sessions = prod_db.collection("Sessions")
prod_stories = prod_db.collection("Stories")

# AWS Connection
aws_config = {access_key_id: "AKIAJTPGKC25LGKJUCTA", secret_access_key: "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"}
AWS.config(aws_config)
s3 = AWS::S3.new
s3_bucket = s3.buckets['homageapp']



remakes = test_remakes.find({"footages.background"=> {"$in"=>["-10","-11"]}})
# puts remakes.count

for remake in remakes do
	puts remake["footages"][0]["background"].to_s
end

# ######################################
# # Updating all remakes with user name
# def user_name(user)
# 	if user["facebook"] then
# 		return user["facebook"]["name"]
# 	elsif user["email"] then
# 		# Getting the prefix of the email ("nir.channes" of "nir.channes@gmail.com")
# 		prefix = user["email"].split("@")[0]

# 		# Replacing dots '.' and underscores '_' with space
# 		prefix.gsub!('.', ' ')
# 		prefix.gsub!('_', ' ')

# 		# Capitalizing each word
# 		name = prefix.split.map(&:capitalize).join(' ')

# 		return name
# 	else
# 		return nil
# 	end
# end

# def update_user_name_in_remakes(user, remakes_collection)
# 	username = user_name(user)

# 	return if !username

# 	remakes = remakes_collection.find({user_id:user["_id"]})
# 	puts "Going to update " + remakes.count.to_s + " with the fullname: " + username
# 	for remake in remakes do
# 		puts "Updating remake " + remake["_id"].to_s + " with fullname: " + username
# 		remakes_collection.update({_id: remake["_id"]}, {"$set" => {user_fullname: username}})
# 	end
# end

# date = Time.parse("20140430Z")
# users = prod_users.find({"$or" => [{created_at:{"$gte"=>date}, facebook:{"$exists"=>true}}, {created_at:{"$gte"=>date}, email:{"$exists"=>true}}]})
# puts users.count
# for user in users do
# 	update_user_name_in_remakes(user, prod_remakes)
# end
# ######################################



# homage_campaign = test_campaigns.find_one({name: "Homage App"})
# homage_campaign_id = homage_campaign["_id"]
# puts "homage_campaign_id: " + homage_campaign_id.to_s
# stories = test_stories.find({active:true})
# for story in stories do 
# 	story_id = story["_id"]
# 	test_stories.update({_id: story_id},{"$set" => {campaign_id: homage_campaign_id}})
# end


#stories = prod_stories.find({active:true})
#puts stories.count

#for story in stories do
#	puts story["name"]
#	for scene in story["scenes"] do
#		puts scene["contours"]["360"]["contour"] if scene["contours"]
#	end
#end

# def download_from_url (url, local_path)
# 	File.open(local_path, 'wb') do |file|
# 		file << open(url).read
#     end	
# end

# file_names = [
# 	"5446fb860be0440579000004_1_1413938083569",
# 	"5446fb860be0440579000004_2_1413938113953",
# 	"544656b20be0443169000001_1_1413895919",
# 	"5444f2ac0be044048500000d_3_1413804787",
# 	"5445bee10be0447fa5000013_4_1413857044",
# 	"544539f70be04440ad000001_2_1413823108"
# ]

# for file_name in file_names do
# 	remake_id = BSON::ObjectId.from_string(file_name.split("_")[0])
# 	scene_id = file_name.split("_")[1].to_i

# 	remake = prod_remakes.find_one(remake_id)
# 	story_id = remake["story_id"]
# 	story = prod_stories.find_one(story_id)
# 	contour_url = story["scenes"][scene_id - 1]["contours"]["360"]["contour_remote"]
# 	face_contour_url = File.join( File.dirname(contour_url) + "/Face" , File.basename(contour_url,".*") + "-face.ctr" )
# 	local_path = '/Users/tomer/Downloads/checkstuckalgo/' + file_name + '.ctr'

# 	File.open(local_path, 'wb') do |file|
# 		file << open(face_contour_url).read
#     end	

#     puts local_path + " successfully saved"
# end


# date = "fdd"
# x = Date.parse(date)
# puts x

# remake_ids = [
# "5430e39a0be0443f86000009", 
# "5430e3ed0be0443f8600000a", 
# "5430e44f0be0443f8600000b", 
# "5430e5f30be0443f8600000f", 
# "5430e67b0be0443f86000010", 
# "5430e6dd0be0443f86000011", 
# "5430e73e0be0443f86000013", 
# "5430e7a40be0443f86000014", 
# "5430e80e0be0444456000001", 
# "5430ebba0be0443f86000017", 
# "54322a1b0be0447060000001", 
# "54322a630be0447060000003", 
# "543232fe0be04463b4000006", 
# ]


# # for remake_id in remake_ids do
# # 	remake = prod_remakes.find_one(BSON::ObjectId.from_string(remake_id))
# # 	puts "remake: " + remake["_id"].to_s + "; status = " + remake["status"].to_s + "; render_start=" + remake["render_start"].to_s

# # 	# response = Net::HTTP.post_form(prod_render, {"remake_id" => remake_id.to_s})
# # 	# puts response
# # end

# date = Time.parse("20141005Z")
# remakes = prod_remakes.find(render_start:{"$gte"=>date})
# for remake in remakes do
# 	puts "remake: " + remake["_id"].to_s + "; status = " + remake["status"].to_s + "; render_start=" + remake["render_start"].to_s
# end



# fix_stories = stories.find(active_from: {"$exists"=>true})
# for story in fix_stories do
# 	next if story["name"] == "Test"
# 	puts story["name"]
# 	scene_id = 1
# 	for scene in story["scenes"]
# 		#puts "scene id=" + scene_id.to_s
# 		contour = scene["contours"]["360"]["contour"]
# 		#puts "contour=" + contour

# 		#face_contour = contour.split(".")[0] + "-face" + ".ctr"
# 		#puts "face contour=" + face_contour
# 		#new_contour = contour
		
# 		#result = stories.update({_id: story["_id"], "scenes.id" => scene_id}, {"$set" => {"scenes.$.contours.360.contour" => face_contour}})
# 		#puts result


# 		scene_id += 1
# 	end
# end
#puts fix_stories.count

# successful_upload_num = 0
# scenes_to_process = 0
# failed_users = Set.new
# date = Time.parse("20140923Z")
# failed_remakes = prod_remakes.find(created_at:{"$gte"=>date}, render_start:{"$exists"=>true}, render_end:{"$exists"=>false})
# remakes_to_fix = Array.new
# puts "Total Failed Remakes = " + failed_remakes.count.to_s
# for remake in failed_remakes do
# 	fix_remake = true
# 	raw_scene_prefix = "Remakes/" + remake["_id"].to_s + "/raw_scene"
# 	s3_objects = s3_bucket.objects.with_prefix(raw_scene_prefix)

# 	if s3_objects.count == remake["footages"].count then
# 		successful_upload_num += 1
# 		#puts "status = " + remake["status"].to_s
# 		failed_users.add(remake["user_id"])

# 		for footage in remake["footages"] do
# 			processed_scene_prefix = "Remakes/" + remake["_id"].to_s + "/processed_scene_" + footage["scene_id"].to_s
# 			s3_processed_objects = s3_bucket.objects.with_prefix(processed_scene_prefix)
# 			if s3_processed_objects.count == 0 then
# 				# resend scene to processing
# 				remake_id = remake["_id"].to_s
# 				scene_id = footage["scene_id"]
# 				take_id = footage["take_id"]
# 				puts '["' + remake_id + '", ' + '"' + scene_id.to_s + '", "' + take_id + '"],'
# 				scenes_to_process += 1
# 				fix_remake = false
# 			end
# 		end

# 		remakes_to_fix.push(remake["_id"]) if fix_remake


# 		# unprocessed_scenes = Array.new
# 		# for footage in remake["footages"] do
# 		# 	processed_scene_prefix = "Remakes/" + remake["_id"].to_s + "/processed_scene_" + footage["scene_id"].to_s
# 		# 	s3_processed_objects = s3_bucket.objects.with_prefix(processed_scene_prefix)
# 		# 	if s3_processed_objects.count == 0 then
# 		# 		unprocessed_scenes.push(footage["scene_id"])
# 		# 	end
# 		# end

# 		# if unprocessed_scenes.count > 0 then
# 		# 	#puts remake["_id"].to_s + " has unprocessed scenes: " + unprocessed_scenes.to_s + " out of " + remake["footages"].count.to_s + " scenes" 
# 		# else
# 		# 	#puts remake["_id"].to_s + " (all scenes processed)"
# 		# end
# 	else
# 		#upload_error_num += 1
# 	end
# end
# puts "Scenes to process = " + scenes_to_process.to_s
# puts "Faild not due to upload = " + successful_upload_num.to_s
# puts "Remakes to fix = " + remakes_to_fix.count.to_s
# puts "Users failed not due to upload = " + failed_users.count.to_s

# emails = Array.new
# for user_id in failed_users do
# 	user = prod_users.find_one(user_id)
# 	emails.push(user["email"]) if user["email"]
# end
# puts "Users failed with email = " + emails.count.to_s

# for email in emails do
# 	puts email
# end

# for remake_id in remakes_to_fix do
# 	puts '"' + remake_id.to_s + '",'
# end


# def median(array)
#   sorted = array.sort
#   len = sorted.length
#   return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
# end


# res = prod_sessions.find({start_time: {"$gte"=>Time.parse("20140830Z"),"$lt"=>Time.parse("20140831Z")}})
# puts res.count

# array = Array.new()
# result = 0.0
# for session in res do
# 	puts session["duration_in_minutes"]
# 	result += session["duration_in_minutes"].to_f
# 	array.push(session["duration_in_minutes"].to_f)
# end

# puts "median"
# puts median(array)

# puts "avg"
# puts result/res.count


# res = prod_remakes.find({created_at: {"$gte"=>Time.parse("20140910Z"),"$lt"=>Time.parse("20140911Z")}, share_link:{"$exists"=>true}})
# puts res.count

# user_ids = Set.new
# remake_ids = Array.new
# for remake in res do
# 	user_ids.add(remake["user_id"])
# 	remake_ids.push(remake["_id"])
# end

# puts "user_ids count"
# puts user_ids.count

# res = prod_shares.find({created_at: {"$gte"=>Time.parse("20140902Z"),"$lt"=>Time.parse("20140911Z")}, remake_id:{"$in"=>remake_ids}})

# remake_ids = Set.new
# user_ids = Set.new
# for share in res do
# 	user_ids.add(share["user_id"])
# end

# puts user_ids.count

# remakes = ["53ecdebe0be0440cdc000009","53ee5f2f0be0445d5d00000b","53ee10210be0443520000008","53ee6d690be0446c45000006","53ee820f0be0447547000009","53ee91a90be044754700001e","53ef08270be0443897000015","53ef61560be0447457000003","53efbd5a0be04428b9000004","53f018a80be0445c23000008","53f0b3480be044333e00000d","53f0fe0b0be0445ecc000001","53f128290be0447785000001","53f1e5500be0445cff000003","53f20ac20be044732b000007","53f222480be04475b8000014","53f2ee050be0447036000001","53f3521d0be0442536000008","53f3d4250be04469b6000011","53f4b4a30be04468aa000002","53f4db890be0447c81000008","53f4ebf60be0440625000003","53f510ee0be0441c67000002","53f525dc0be0441f7c00000b","53f541030be04433c0000001","53f608300be0441f65000002","53f6c24e0be0447cfc000005","53f6a7f60be04474e3000003","53f751dd0be0445511000001","53f76d190be0445511000008","53f7bf230be0440444000006","53f7f0ac0be044238c000005","53f87e5b0be044495c00000b","53f8803b0be044772d000001","53f891c60be0447ee5000006","53f8aec70be0440ae0000008","53f8e7fb0be0442ecf000002","53f8fe320be04439db000005","53f930340be044569a000001","53f999cc0be0440b50000007","53f99b1f0be0440b50000008","53f9f3d70be04416f8000018","53fa1bbd0be0445662000001","53fa73a90be0440355000007","53fa8c420be0440b15000005","53fa9da80be0441d81000005","53fab8610be044202a000014"]
# puts remakes.count

# for remake_id in remakes do
# 	remake = prod_remakes.find_one(BSON::ObjectId.from_string(remake_id))
# 	puts remake_id + ": " + remake["status"].to_s
# 	# homage_server_uri = URI.parse("http://homage-server-app-prod.elasticbeanstalk.com/render")
# 	# response = Net::HTTP.post_form(homage_server_uri, {"remake_id" => remake_id.to_s})
# 	# puts response
# end



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
