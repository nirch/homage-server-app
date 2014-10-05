require File.expand_path '../mongo_helper.rb', __FILE__
require File.expand_path '../aws_helper.rb', __FILE__
require 'fileutils'
require 'open-uri'

# input
#remake_id = BSON::ObjectId.from_string("5380834b0be044412f000039")
#download_folder = "C:/Development/Homage/Remakes/" + remake_id.to_s + "/"

if !ARGV[0] || !ARGV[1] then 
	puts "usage: download_remake_s3 {-p|-t} {-remake=<remake_id>|-date=YYYYMMDD} [-folder=<folder>]"
end

puts "Production or Test? (p/t)"
env = gets.chomp
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
		

puts "Enter remake to download:"
remake_id_str = gets.chomp

puts

if !BSON::ObjectId.legal?(remake_id_str) then
	puts "Illegal remake ID!"
	exit
end

remake_id = BSON::ObjectId.from_string(remake_id_str)

# Getting the remake
remake = remakes.find_one(remake_id)
if !remake then
	puts "Remake not found!"
	exit
end
story = stories.find_one(remake["story_id"])
puts "remake for story " + '"' + story["name"] + '"'
user = users.find_one(remake["user_id"])
if user["email"] then
	puts "user mail " + '"' + user["email"] + '"'
end

puts

#default_root_download_folder = "C:/Development/Homage/Remakes/"
default_root_download_folder = "/Users/tomer/Desktop/Delete/Remakes/"
puts "Enter download folder (blank for default " + default_root_download_folder + "):"
input_root_download_folder = gets.chomp
if input_root_download_folder.length > 0 then
	folder_chomped = input_root_download_folder.tr('"', '').chomp
	root_download_folder = folder_chomped.gsub /\\+/, '/'
	root_download_folder = root_download_folder + "/"
else
	root_download_folder = default_root_download_folder
end
download_folder = root_download_folder + remake_id.to_s + "/"

puts

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

puts
puts "Remake saved successfully to " + download_folder

