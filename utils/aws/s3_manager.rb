
module AWSManager
	class S3Manager

		attr_accessor :bucket

		class << self

			def emu_dev_test
				s3_manager = self.new
				s3 = AWS::S3.new
				s3_manager.bucket = s3.buckets['homage-emu-dev-test']
				s3_manager
			end

			def emu_dev_prod
				s3_manager = self.new
				s3 = AWS::S3.new
				s3_manager.bucket = s3.buckets['homage-emu-dev-prod']
				s3_manager
			end

			def emu_test
				s3_manager = self.new
				s3 = AWS::S3.new
				s3_manager.bucket = s3.buckets['homage-emu-test']
				s3_manager
			end

			def emu_prod
				s3_manager = self.new
				s3 = AWS::S3.new
				s3_manager.bucket = s3.buckets['homage-emu-prod']
				s3_manager
			end
	    end

	    def download(object_key, local_path)
			AWSManager.logger.info "Downloading file from S3 with key " + object_key
			object = @bucket.objects[object_key]
			File.open(local_path, 'wb') do |file|
		  		object.read do |chunk|
		    		file.write(chunk)
		    	end
		    	file.close
		    end
		  	AWSManager.logger.info "File downloaded successfully to: " + local_path
		  	return object
	    end


		def upload_file(file, s3_key, acl)
			s3_object = @bucket.objects[s3_key]
			AWSManager.logger.info 'Uploading the file <' + file.to_s + '> to S3 path <' + s3_object.key + '>'
			s3_file = s3_object.write(:file => file)
    		s3_file.acl = :public_read
			AWSManager.logger.info "Uploaded successfully to S3, url is: " + s3_object.public_url.to_s
			return s3_object
		end
	    

		def upload(file_path, s3_key, acl, content_type=nil, metadata=nil)
			s3_object = @bucket.objects[s3_key]
			AWSManager.logger.info 'Uploading the file <' + file_path.to_s + '> to S3 path <' + s3_object.key + '>'
			s3_object.write(Pathname.new(file_path), {:acl => acl, :content_type => content_type, :metadata => metadata})
			AWSManager.logger.info "Uploaded successfully to S3, url is: " + s3_object.public_url.to_s
			return s3_object
		end

		def delete(object_key)
			AWSManager.logger.info "Deleting file from S3 with key " + object_key
			s3_object = @bucket.objects[object_key]
			s3_object.delete			
		end

		def get_object(object_key)
			return @bucket.objects[object_key]
		end
	end
end