require File.expand_path '../mongo_helper.rb', __FILE__
require File.expand_path '../aws_helper.rb', __FILE__
require 'fileutils'
require 'open-uri'
require 'logger'

puts "Set up logging"

main_folder = "/Users/dangal/Documents/homage/crashes/"

log = Logger.new(main_folder + 'log.txt') 
log.debug "Log file created"

# input
#remake_id = BSON::ObjectId.from_string("5380834b0be044412f000039")


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


    puts "Downloading remakes from list: " 
    remake_ids_array = ["54e9277afb9b8b72a9000003","54e9277afb9b8b72a9000003","54e5d908fb9b8b1e64000007","54e32ee8fb9b8b2703000003","54e2315ffb9b8b19f8000004","54e1e8b1fb9b8b698c00000a","54e1ab54fb9b8b4d89000003"]
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

		input_root_download_folder = main_folder#ARGV[2]
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
