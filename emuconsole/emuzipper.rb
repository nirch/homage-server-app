require_relative '../utils/aws/aws_manager'
require_relative '../utils/zipper'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require_relative 'logic/helper'
require 'fileutils'

# Main file
def zipEmuPackage(package_name)

	download_folder = "downloadTemp/"
	FileUtils::mkdir_p download_folder

	package = getPackageByName(package_name)

	input_files = getResourcesFromPackage(package)

	download_from_aws(package.name, input_files, download_folder, settings.emu_s3_test)

	zip_file_name = "package_" + package.name + "_" + Time.now.strftime("%Y%m%d") + "_" + Time.now.strftime("%H%M%S")

	zip_package_files(download_folder, input_files, zip_file_name)

	upload_zip_to_s3(download_folder, zip_file_name, settings.emu_s3_test)

	delete_download_folder(download_folder)

	package.last_update = Time.now
	package.cms_last_zip_file_name = zip_file_name + ".zip"
	package.save
end