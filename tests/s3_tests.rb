require '../utils/aws/aws_manager'
require 'minitest/autorun'

class TestS3Manager < MiniTest::Unit::TestCase
	def setup
		@S3Manager = AWSManager::S3Manager.emu_test
		@delete_files = Array.new
		@delete_folder = nil	
	end

	def test_download
		download_key = 'test/dan.gif'
		download_destination = 'resources/party-disco-bg-download.gif'

		assert_equal false, File.exists?(download_destination)
		@S3Manager.download download_key, download_destination
		assert_equal true, File.exists?(download_destination)

		@delete_files.push(download_destination)
	end

	def test_upload
		upload_file = 'resources/party-disco-bg.gif'
		upload_s3_destination = 'test/upload.gif'

		assert_equal false, @S3Manager.get_object(upload_s3_destination).exists?

		# Uploading the Object
		@S3Manager.upload upload_file, upload_s3_destination, :public_read
		assert_equal true, @S3Manager.get_object(upload_s3_destination).exists?

		# Deleting the Object
		@S3Manager.delete upload_s3_destination
		assert_equal false, @S3Manager.get_object(upload_s3_destination).exists?		
	end

	def teardown
  		for file_to_delete in @delete_files do
  			FileUtils.remove_file(file_to_delete) if File.exists?(file_to_delete)
  		end

  		if @delete_folder then
  			FileUtils.remove_dir(@delete_folder) if File.directory?(@delete_folder)
  		end
  	end
end