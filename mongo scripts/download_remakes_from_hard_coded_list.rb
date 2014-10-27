require File.expand_path '../mongo_helper.rb', __FILE__
require File.expand_path '../aws_helper.rb', __FILE__
require 'fileutils'
require 'open-uri'
require 'logger'
log = Logger.new('D:/homage/movies/log.txt') 
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
    remake_ids_array = ["53f1fcb40be04468be000005", "53f3f7260be0440266000003", "543581a20be04427ca000007", "54204f370be044023f000001", "544296310be04445ee000001", "544815ed0be0441f16000004", "5432e4cb0be044548e000001", "544445c60be0443b82000001", "5442b1290be0445918000001", "543edd990be0443e3b000008", "5431c2b60be0443628000004", "542560c70be0443d42000009", "53f9a8c90be04416f8000006", "5445b1e90be0447fa5000003", "543a398f0be0444219000005", "542da14c0be0447b3c000003", "5404974d0be0446955000008", "53fbae540be0442ed8000002", "53ea40df0be044141300001b", "5420b4970be0443bb4000001", "54422bf20be0440ca9000001", "53ea3fec0be0441413000018", "53fe9c640be0444f3a000002", "541293610be0444507000002", "542dbc940be0440335000007", "53fa71100be0440355000002", "53fe9c640be0444f3a000002", "5445806d0be0446647000001", "542fe0e10be04430b8000001", "53e3cc260be0444dc7000001", "542920330be044417d000001", "53ee820f0be0447547000009", "543e7ecb0be04414df000001", "543c3fdf0be044488a000012", "54425eb10be044278e000004", "53f4eaa00be0440625000002", "53fc69490be04410d0000002", "5432e4cb0be044548e000001", "53e3cc260be0444dc7000001", "53f1fcb40be04468be000005", "542c63370be0447ded000003", "5445004a0be04420ef0000", "543581a20be04427ca000007", "53ee91a90be044754700001e", "543a2c750be0442c1600001a", "541423890be04415e0000003", "53fbdb960be04444ff000010", "53f3396d0be0441219000011", "53fb71c80be04411bf000001", "5443096c0be0440487000007", "544308a40be0440487000006", "5445b0450be0447fa5000001", "53fe9c640be0444f3a000002", "541482330be0444e74000002", "53f9a8c90be04416f8000006", "5443096c0be0440487000007", "544308a40be0440487000006", "53f9a8c90be04416f8000006"]
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

		input_root_download_folder = "D:/homage/movies/" #ARGV[2]
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
