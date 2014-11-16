require 'aws-sdk'
require 'mongo'
require 'date'
require 'time'
require 'logger' 

log = Logger.new('D:/homage/movies/log.txt') 
log.debug "Log file created"

aws_config = {access_key_id: "AKIAJTPGKC25LGKJUCTA", secret_access_key: "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"}
	AWS.config(aws_config)


test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
test_users = test_db.collection("Users")
test_remakes = test_db.collection("Remakes")
test_stories = test_db.collection("Stories")

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")
prod_shares = prod_db.collection("Shares")
prod_sessions = prod_db.collection("Sessions")
prod_stories = prod_db.collection("Stories")



def download_from_s3 (s3_key, local_path)
	s3 = AWS::S3.new
	bucket = s3.buckets['homageapp']

	#logger.info 
	puts "Downloading file from S3 with key " + s3_key
	s3_object = bucket.objects[s3_key]

	File.open(local_path, 'wb') do |file|
  		s3_object.read do |chunk|
    		file.write(chunk)
    	end
    	file.close
    end

  	#logger.info 
  	puts "File downloaded successfully to: " + local_path
end

def upload_to_s3 (file_path, s3_key, acl, content_type=nil)
	s3 = AWS::S3.new
	bucket = s3.buckets['homageapp']
	s3_object = bucket.objects[s3_key]

	#logger.info 
	puts 'Uploading the file <' + file_path + '> to S3 path <' + s3_object.key + '>'
	#file = File.new(file_path)
	s3_object.write(Pathname.new(file_path), {:acl => acl, :content_type => content_type})
	#file.close
	#logger.info 
	puts "Uploaded successfully to S3, url is: " + s3_object.public_url.to_s

	return s3_object
end

#def logger (message)
#	puts message
#end

#ready_remakes = test_remakes.find({share_link:{"$exists"=>true}})
#puts ready_remakes.count

launch_date = Time.parse("20140601Z")

i = 0

# Number of failed remakes, remakes that were clicked on create movie but were not done
#total_remakes = prod_remakes.find(created_at:{"$gte"=>launch_date})

ready_remakes = prod_remakes.find({created_at:{"$gte"=>launch_date}, status:3}).each do |r|
	#puts ready_remakes.count
	#, {:limit => 10}
	#download_from_s3 (s3_key, 'D:\homage\movies')
	if (not r["footages"] == nil and not r["footages"][0] == nil)
		begin
			i = i + 1
			log.info i
			# create variables
			#-----------------
			file_name = r["_id"].to_s
			movie_extension = ".mov"
			thumbnail_extension = "_raw1.jpg"
			file_path = "D:/homage/movies/"
			s3_key = r["footages"][0]["raw_video_s3_key"]
			s3_upload_key = File.dirname(s3_key).to_s + "/" + file_name + thumbnail_extension
			log.info "Creating Variables: " + "s3_key: " + s3_key + "s3_upload_key: " + s3_upload_key
			
			# download raw1 file from s3
			#----------------------------
			log.info "Start download"
			download_from_s3(s3_key,file_path + file_name + movie_extension)
			log.info "Finished Downloading successfully"
			#puts r["footages"][0]["raw_video_s3_key"].to_s
			#puts r["_id"].to_s

			#create thumbnail of raw1
			#------------------------
			system "ffmpeg -ss 0 -i " + file_path + file_name + movie_extension + " -frames:v 1 -vf crop=640:360 -y " + file_path + file_name + thumbnail_extension
			log.info "ffmpeg::::::: " + "ffmpeg -ss 0 -i " + file_path + file_name + movie_extension + " -frames:v 1 -vf crop=640:360 -y " + file_path + file_name + thumbnail_extension
			#system "ffmpeg -y -i " + file_path + file_name + movie_extension + " -f mjpeg -ss 10 -vframes 1 640x360 " + file_path + file_name + thumbnail_extension
			
			#upload thumbnail of raw1 to s3
			#--------------------------
			log.info "Start upload"
			upload_to_s3 file_path + file_name + thumbnail_extension, s3_upload_key, :public_read, 'image/jpeg'
			log.info "Finished Uploading successfully"
			puts "file endings!!!!!!!!!!!!!!!!!!!!!!!!!" + s3_key.to_s + "    " + s3_upload_key.to_s
			
			#delete the movie after uploading the thumbnail
			#------------------------------------------------
			File.delete(file_path + file_name + movie_extension)
			File.delete(file_path + file_name + thumbnail_extension)
			rescue => err
				log.error ":::::::Failed to process::::: " + file_name + "::::::::"
				log.error err
		end
	end
end
#ready_remakes.each do |remk|
 # puts 'I love ' + remk + '!'
  #puts 'Don\'t you?'
#end