require File.expand_path '../mongo_helper.rb', __FILE__
require File.expand_path '../aws_helper.rb', __FILE__
require 'fileutils'
require 'open-uri'
require 'logger'
log = Logger.new('D:/homage/others/log.txt') 
log.debug "Log file created"

# input
#remake_id = BSON::ObjectId.from_string("5380834b0be044412f000039")
#download_folder = "C:/Development/Homage/Remakes/" + remake_id.to_s + "/"

# if !ARGV[0] || !ARGV[1] || !ARGV[2] then 
# 	puts "usage: download_remakes p|t <remake_id>|<YYYYMMDD> <destination_folder>"
# 	exit
# end

env = "p"#ARGV[0]
if env == "p" || env == "P" then
	remakes = PROD_REMAKES
	users = PROD_USERS
	stories = PROD_STORIES
elsif env == "t" || env == "T" then
	remakes = TEST_REMAKES
	users = TEST_USERS
	stories = TEST_STORIES
else
	puts "enter 'p' or 't' goddammit!"
	exit
end
		
#remake_id_str = ARGV[1]

puts


    puts "Downloading remakes from list: " 
    remake_ids_array = ["54538db90be0441e75000007","54538d4c0be0442095000005","54538bef0be0441e75000005","54538c670be0441e75000006","54538b1d0be0442095000002","54538b570be0442095000003","54538ade0be0442095000001","54538a2e0be0441e75000004","545387b80be044093b000007","5453875e0be044093b000006","5445b0ee0be0446f62000012","53fc69490be04410d0000002"]
    puts "before uniq " + remake_ids_array.count.to_s + " remakes..." 
    remake_ids_array = remake_ids_array.uniq
    puts "after uniq " + remake_ids_array.count.to_s + " remakes..." #end

   # remakes_to_download = remakes.find({"_id":{"$in"=>remake_ids_array}})

for remake_id_str in remake_ids_array do
	begin
		#remake_id = remake["_id"]
		puts remake_id_str.to_s
		remake_id = BSON::ObjectId.from_string(remake_id_str)
		remake = remakes.find_one(remake_id)

		puts "Downloading remake " + remake_id.to_s

		if !remake then
			puts "Remake: " + remake_id.to_s + " not found!"
			break
		end
		story = stories.find_one(remake["story_id"])
		puts "remake for story " + '"' + story["name"] + '"'
		user = users.find_one(remake["user_id"])
		if user["email"] then
			puts "user mail " + '"' + user["email"] + '"'
		end

		puts

		input_root_download_folder = "D:/homage/others/" #ARGV[2]
		if input_root_download_folder.length > 0 then
			folder_chomped = input_root_download_folder.tr('"', '').chomp
			root_download_folder = folder_chomped.gsub /\\+/, '/'
			root_download_folder = root_download_folder + "/"
		else
			root_download_folder = default_root_download_folder
		end
		download_folder = root_download_folder + remake_id.to_s + "/"

		

		# Creating the download folder
		FileUtils.mkdir download_folder

		# Getting all the remake's file from S3
		remake_s3_prefix = "Remakes/" + remake["_id"].to_s
		remake_s3_objects = HOMAGE_S3_BUCKET.objects.with_prefix(remake_s3_prefix)
		for remake_s3_object in remake_s3_objects do
			# Saving each file to the download folder
			basename = remake_id.to_s + "_" + File.basename(remake_s3_object.key, ".*")
			extension = File.extname(remake_s3_object.key)
			download_to_path = download_folder + basename + extension

			puts "Downloading file " + File.basename(remake_s3_object.key) + "..."
			download_from_s3(remake_s3_object, download_to_path)

			if remake_s3_object.key.include? "raw_scene" then
				scene_id = basename[-1,1].to_i # The last char is the scene_id
				contour_orig_url = story["scenes"][scene_id - 1]["contours"]["360"]["contour_remote"]
				contour_face_url = File.dirname(contour_orig_url) + "/Face/" + File.basename(contour_orig_url,".*") + "-face.ctr"

				extension = ".ctr"
				download_to_path = download_folder + basename + extension

				puts "Downloading file " + File.basename(contour_face_url) + "..."
				open(download_to_path, 'wb') do |file|
					file << open(contour_face_url).read
				end
			end
		end
		puts "Remake saved successfully to " + download_folder
		rescue => err
				log.error ":::::::Failed to process::::: " + remake_id_str.to_s + "::::::::"
				log.error err
	end
end
