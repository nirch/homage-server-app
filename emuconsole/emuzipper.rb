require_relative '../utils/aws/aws_manager'
require_relative '../utils/zipper'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require 'fileutils'

# Main file
def zipEmuPackage(package_name)

	download_folder = "downloadTemp/"
	FileUtils::mkdir_p download_folder

	package = getPackageByName(package_name)

	input_files = getFileNamesFromPackage(package)

	download_from_aws(package.name, input_files, download_folder)

	zip_file_name = "package_" + package.name + "_" + Time.now.strftime("%Y%m%d") + "_" + Time.now.strftime("%H%M%S")

	zip_package_files(download_folder, input_files, zip_file_name)

	upload_zip_to_s3(download_folder, zip_file_name)

	delete_download_folder(download_folder)

	package.last_update = Time.now
	package.save
end

# get files to download from aws
def getFileNamesFromPackage(package)
	input_files = []

	icon2x = package.cms_icon_2x
	input_files.push icon2x
	icon3x = package.cms_icon_3x
	input_files.push icon3x

	source_user_layer_mask = package.emuticons_defaults["source_user_layer_mask"]
	if source_user_layer_mask != nil && source_user_layer_mask != ""
		
		input_files.push source_user_layer_mask
	end

	for emuticon in package.emuticons do

		source_back_layer = emuticon.source_back_layer
		if source_back_layer != nil && source_back_layer != ""
			input_files.push source_back_layer
		end

		source_front_layer = emuticon.source_front_layer
		if source_back_layer != nil && source_back_layer != ""
			input_files.push source_front_layer
		end

		source_user_layer_mask = emuticon.source_user_layer_mask
		if source_user_layer_mask != nil && source_user_layer_mask != ""
			input_files.push source_user_layer_mask
		end
	end

	return input_files
end


# download files
def download_from_aws(package_name, input_files, download_folder)
		for f in input_files do
			filename = package_name + "/" + f
			object_key = "packages/" + filename
			local_path = download_folder + f
			settings.emu_s3_test.download(object_key, local_path)

		end
end


# def upload_file_to_s3(pack_name, file, file_name)
# 	s3_key = 'packages/' + pack_name + '/' + file_name
# 	s3_object = settings.emu_s3_test.upload(file[:tempfile].path, s3_key, :public_read, file[:type])
# 	if s3_object != nil && s3_object.public_url != nil
# 		return true
# 	else
# 		return false
# 	end
# 	FileUtils.rm(file[:tempfile].path)
# end


# zip files
def zip_package_files(download_folder, input_filenames, zip_file_name)
	zipfolder(download_folder, input_filenames, zip_file_name)
end

# upload zip file to zipped_packages/
# zipped_packages/package_attitude_20150329_114643.zip
# ********************
def upload_zip_to_s3(file_path, filename)
	s3_key = "zipped_packages/" + filename + ".zip"
	settings.emu_s3_test.upload(file_path + filename + ".zip", s3_key, :public_read, content_type=nil, metadata=nil)
end


# delete download folder
def delete_download_folder(download_folder)
	FileUtils.rm_rf(download_folder)
end
