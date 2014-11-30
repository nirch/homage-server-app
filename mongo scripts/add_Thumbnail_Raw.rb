require 'aws-sdk'
require 'mongo'
require 'date'
require 'time'
require 'logger' 
require 'mini_exiftool'
require 'open-uri'

system_folder = File.dirname(__FILE__)
#system_folder = "D:"

log = Logger.new(system_folder + '/homage/makeThumbnails/log.txt') 
log.debug "Log file created"

aws_config = {access_key_id: "AKIAJTPGKC25LGKJUCTA", secret_access_key: "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"}
	AWS.config(aws_config)
testorprod = "test"

if testorprod == "test"
	db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
	users = db.collection("Users")
	remakes = db.collection("Remakes")
	stories = db.collection("Stories")
elsif testorprod == "prod"
	db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
	users = db.collection("Users")
	remakes = db.collection("Remakes")
	shares = db.collection("Shares")
	sessions = db.collection("Sessions")
	stories = db.collection("Stories")
end

s3 = AWS::S3.new
bucket = s3.buckets['homageapp']


def download_from_s3 (s3_key, local_path)
	s3 = AWS::S3.new
	bucket = s3.buckets['homageapp']
	#logger.info 
	# log.info "Downloading file from S3 with key " + s3_key
	s3_object = bucket.objects[s3_key]
	File.open(local_path, 'wb') do |file|
  		s3_object.read do |chunk|
    		file.write(chunk)
    	end
    	file.close
    end

  	#logger.info 
  	# log.info "File downloaded successfully to: " + local_path
end

def upload_to_s3 (file_path, s3_key, acl, content_type=nil)
	s3 = AWS::S3.new
	bucket = s3.buckets['homageapp']
	s3_object = bucket.objects[s3_key]

	#logger.info 
	# log.info 'Uploading the file <' + file_path + '> to S3 path <' + s3_object.key + '>'
	#file = File.new(file_path)
	s3_object.write(Pathname.new(file_path), {:acl => acl, :content_type => content_type})
	#file.close
	#logger.info 
	# log.info "Uploaded successfully to S3, url is: " + s3_object.public_url.to_s

	return s3_object
end

#def logger (message)
#	puts message
#end

#ready_remakes = test_remakes.find({share_link:{"$exists"=>true}})
#puts ready_remakes.count

launch_date = Time.parse("20141101Z")

i = 0
rotated_video = false



#overwrite = false  "Remakes/52d7fd79db25451694000001/raw_scene_1.mov"
# download_from_s3("Remakes/52d7fd79db25451694000001/raw_scene_1.mov","D:/homage/makeThumbnails/" +"5332ecd18bb1eb2bd1000001" + ".mov") 
# Number of failed remakes, remakes that were clicked on create #
#movie but were not done #total_remakes = #
#prod_remakes.find(created_at:{"$gte"=>launch_date})

#Variables
#----------------------
movie_extension = ".mov"
ctr_extension = ".ctr"
thumbnail_extension = "_raw1.jpg"
file_path = system_folder + "/homage/makeThumbnails/"
background_detection_algorithm = 
background_folder = "backgrounddetection/"
xml_file = background_folder + "parameters.xml"
download_contour_path = ""
background_value = "-99"

ready_remakes = remakes.find({created_at:{"$gte"=>launch_date}, status:3}).each do |r|
	#puts ready_remakes.count
	#, {:limit => 10}
	#download_from_s3 (s3_key, 'D:\homage\movies')
	if(not r["footages"] == nil and not r["footages"][0] == nil)
		begin
			rotated_video = false
			i = i + 1
			log.info i
			# create variables
			#-----------------
			remake_id = r["_id"]
			file_name = remake_id.to_s
			s3_key = r["footages"][0]["raw_video_s3_key"]
			s3_upload_key = File.dirname(s3_key).to_s + "/" + file_name + thumbnail_extension
			log.info "Creating Variables: " + "s3_key: " + s3_key + "s3_upload_key: " + s3_upload_key
			video_path = file_path + file_name + movie_extension
			video_path_flipped = file_path + file_name + "f" + movie_extension
			thumbnail_path = file_path + file_name + thumbnail_extension
			remake_s3_object = bucket.objects[s3_key]
			
			# download raw1 file from s3
			#----------------------------
			log.info "s3_key : " + s3_key
			log.info "video_path : " + video_path

			download_from_s3(s3_key,video_path)
			log.info "Finished Downloading successfully"
			#puts r["footages"][0]["raw_video_s3_key"].to_s
			#puts r["_id"].to_s

			#Check if movie upside down and flip thumbnail if needed
			#-----------------------------------------------
			log.info "--------------------------------Start MiniExifTool--------------------------"
			video_metadata = MiniExiftool.new(video_path)
			if(video_metadata.Rotation == 180)
				rotated_video = true
				system 'ffmpeg -i ' + video_path + ' -metadata:s:v rotate="0" -vf "hflip,vflip" -c:v libx264 -crf 23 -acodec copy ' + video_path_flipped
				log.info "Flipped Movie: " + video_path
			end

			log.info "------------------------------Finished MiniExifTool-------------------------"

			# #create thumbnail of raw1
			# #------------------------
			if rotated_video
				system "ffmpeg -ss 0 -i " + video_path_flipped + " -frames:v 1 -vf crop=640:360 -y " + thumbnail_path
			else
				system "ffmpeg -ss 0 -i " + video_path + " -frames:v 1 -vf crop=640:360 -y " + thumbnail_path
			end
			log.info "ffmpeg::::::: " + "ffmpeg -ss 0 -i " + video_path_flipped + " -frames:v 1 -vf crop=640:360 -y " + thumbnail_path

			# #upload thumbnail of raw1 to s3
			# #--------------------------
			log.info "Start upload"
			s3_upload_object = upload_to_s3 thumbnail_path, s3_upload_key, :public_read, 'image/jpeg'
			log.info "Finished Uploading successfully"
			log.info "file endings!!!!!!!!!!!!!!!!!!!!!!!!!" + s3_key.to_s + "    " + s3_upload_key.to_s
			
			#Get Contour
			##-----------------------------------------------
			story = stories.find_one(r["story_id"])
			basename = remake_id.to_s + "_" + File.basename(remake_s3_object.key, ".*")
			scene_id = basename[-1,1].to_i
			contour_orig_url = story["scenes"][scene_id - 1]["contours"]["360"]["contour_remote"]
			log.info "Downloading file " + File.basename(contour_orig_url) + "..."
			download_contour_path = file_path + basename + ctr_extension
			log.info "download_contour_path: " + download_contour_path
			log.info "contour_orig_url: " + contour_orig_url
			log.info "*********Downloading Contour**********"
			open(download_contour_path, 'wb') do |file|
				file << open(contour_orig_url).read
			end
			log.info "*********Finished Downloading Contour**********"
			
			#Get the output from The Background Detection exe
			##-----------------------------------------------
			#'cd ' + background_folder + ' && 
			background_detection_run = background_folder + 'UmBackgroundCA.exe -P' + xml_file + ' ' + download_contour_path + ' ' + thumbnail_path + ' x.txt'
			log.info 'cd ' + background_folder + ' && UmBackgroundCA.exe -P' + xml_file + ' ' + download_contour_path + ' ' + thumbnail_path + ' x.txt'
			getvalue = []
			IO.popen(background_detection_run) do |output|
				getvalue = output.readlines
			end
			for i in 0..getvalue.length
				if getvalue[i] != nil
					if  getvalue[i].include? "background: "
						background_value = getvalue[i].split(": ")[1].gsub("\n",'') #.slice! "\n"
						log.info 'background_value: ' + background_value
						log.info 'getvalue[i]: ' + getvalue[i].split(": ")[1]
					end
				end
			end
			log.info "background_value: " + background_value.to_s

			#Update Mongodb With the background_value
			##---------------------------------------
			log.info "updating Mongo "
			remakes.update({_id: remake_id, "footages.scene_id" => scene_id}, {"$set" => {"footages.$.background" => background_value}})
			remakes.update({_id: remake_id, "footages.scene_id" => scene_id}, {"$set" => {"footages.$.raw_thumbnail" => s3_upload_object.public_url.to_s}})
			log.info "Finished updating Mongo "
			# #delete the movie after uploading the thumbnail
			# #------------------------------------------------
			log.info "Deleting Files"
			File.delete video_path
			if rotated_video
				File.delete video_path_flipped
			end
			File.delete thumbnail_path
			File.delete download_contour_path
			log.info "Files Deleted bye bye..."

		rescue Exception => err
			log.info ":::::::Failed to process::::: " + file_name + "::::::::"
			log.error err
			
			
		end
	end
end
#ready_remakes.each do |remk|
 # puts 'I love ' + remk + '!'
  #puts 'Don\'t you?'
#end