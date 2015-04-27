require_relative '../utils/aws/aws_manager'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require_relative 'logic/helper'
require 'fileutils'
require 'time'

# Main file
def zipEmuPackage(package_name)

	package = getPackageByName(package_name, settings.emu_scratchpad)
	package.cms_proccessing = true
	package.save

	begin 
		success = true
		message = "start"

		download_folder = "downloadTemp/"
		FileUtils::mkdir_p download_folder

		package = getPackageByName(package_name, settings.emu_scratchpad)
		message = "input_files"
		input_files = getResourcesFromPackage(package.name, false, message)
		

		message = "download_from_aws"
		success = download_from_aws(package.name, input_files, download_folder, settings.emu_s3_test)
		
		zip_file_name = ""
		if(success == true)
			currentdatetime = Time.now.utc.iso8601
			
			zip_file_name = "package_" + package.name + "_" + ("%02d" % Time.parse(currentdatetime).year).to_s + ("%02d" % Time.parse(currentdatetime).month).to_s + ("%02d" % Time.parse(currentdatetime).day).to_s + "_" + ("%02d" % Time.parse(currentdatetime).hour).to_s + ("%02d" % Time.parse(currentdatetime).min).to_s + ("%02d" % Time.parse(currentdatetime).sec).to_s
			message = "zip_package_files zip_file_name: " + zip_file_name.to_s
			success = zip_package_files(download_folder, input_files, zip_file_name)
		end
		
		if(success == true)
			message = "upload_zip_to_s3"
			success = upload_zip_to_s3(download_folder, zip_file_name, settings.emu_s3_test)
		end
		message = "delete_download_folder"
		delete_download_folder(download_folder)
		

		if(success == true)
			message = "package.save"
			package.last_update = Time.parse(currentdatetime)
			package.zipped_package_file_name = zip_file_name + ".zip"
			package.cms_state = "save"
			package.save
		end

		return success

	rescue StandardError => e

		return "zipEmuPackage: " + message + "  error: " + e.to_s

	ensure
		package = getPackageByName(package_name, settings.emu_scratchpad)
		package.cms_proccessing = false
		package.save
	end


	
end