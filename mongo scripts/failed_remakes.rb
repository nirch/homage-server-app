require 'mongo'
require 'date'
require 'time'
require 'aws-sdk'

# Mongo production connection
prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")

# AWS Connection
aws_config = {access_key_id: "AKIAJTPGKC25LGKJUCTA", secret_access_key: "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"}
AWS.config(aws_config)
s3 = AWS::S3.new
s3_bucket = s3.buckets['homageapp']

launch_date = Time.parse("20150725Z")

# Number of failed remakes, remakes that were clicked on create movie but were not done
total_remakes = prod_remakes.find(created_at:{"$gte"=>launch_date})
failed_remakes = Array.new
for remake in total_remakes do
	if remake["render_start"] && !remake["render_end"] then
		failed_remakes.push(remake)
	end
end
puts "Number of failed remakes: " + failed_remakes.count.to_s

# Analyzing each remake
upload_error_num = 0
upload_failed_remakes = Array.new
failed_not_upload = Array.new
for remake in failed_remakes do
	raw_scene_prefix = "Remakes/" + remake["_id"].to_s + "/raw_scene"
	s3_objects = s3_bucket.objects.with_prefix(raw_scene_prefix)

	if s3_objects.count == remake["footages"].count then
		#failed_not_upload.push(remake)

		unprocessed_scenes = Array.new
		for footage in remake["footages"] do
			processed_scene_prefix = "Remakes/" + remake["_id"].to_s + "/processed_scene_" + footage["scene_id"].to_s
			s3_processed_objects = s3_bucket.objects.with_prefix(processed_scene_prefix)
			if s3_processed_objects.count == 0 then
				unprocessed_scenes.push(footage["scene_id"])
			end
		end

		if unprocessed_scenes.count > 0 then
			puts remake["_id"].to_s + " has unprocessed scenes: " + unprocessed_scenes.to_s + " out of " + remake["footages"].count.to_s + " scenes" 
		else
			puts remake["_id"].to_s + " (all scenes processed)"
		end
	else
		upload_failed_remakes.push(remake)
		upload_error_num += 1
	end
end

upload_error_percent = upload_error_num.to_f / failed_remakes.count.to_f * 100
puts upload_error_percent.round.to_s + "% failed due to upload error (" + upload_error_num.to_s + " remakes)"

puts "User details for remakes not uploading"
for remake in upload_failed_remakes do
	user = prod_users.find_one(remake["user_id"])

	puts "User details for remake " + remake["_id"].to_s
	puts "User id: " + user["_id"].to_s
	puts "User name: " + remake["user_fullname"] if remake["user_fullname"]
	puts "User device info: " + user["devices"].to_s 
	puts
end

# puts "Remakes that failed not because of upload:"
# for remake in failed_not_upload do
# 	puts remake["_id"].to_s
# end

