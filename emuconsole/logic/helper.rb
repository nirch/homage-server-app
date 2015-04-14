require_relative '../../utils/aws/aws_manager'
require_relative '../model/emuticon'
require_relative '../model/package'

# zip files
def zip_package_files(download_folder, input_filenames, zip_file_name)
	zipfolder(download_folder, input_filenames, zip_file_name)
end

# upload zip file to zipped_packages
def upload_zip_to_s3(file_path, filename, connection)
	if !filename.include? ".zip"
		filename += ".zip"
	end
	s3_key = "zipped_packages/" + filename
	connection.upload(file_path + filename, s3_key, :public_read, content_type=nil, metadata=nil)
end

# upload zip file to zipped_packages
def download_zip_from_s3(file_path, filename, connection)
	s3_key = "zipped_packages/" + filename
	connection.download(s3_key, file_path + filename)
end


# delete download folder
def delete_download_folder(folder)
	FileUtils.rm_rf(folder)
end

# get files to download from aws
def getResourcesFromPackage(package)
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
def download_from_aws(package_name, input_files, download_folder, connection)

	for f in input_files do

		filename = package_name + "/" + f
		object_key = "packages/" + filename
		local_path = download_folder + f
		connection.download(object_key, local_path)

	end

end

# upload files
def upload_to_aws(package_name, input_files, download_folder, connection)

	for f in input_files do
		local_path = download_folder + f
		upload_filepath_to_s3(package_name,local_path, f, "image/*", connection)
	end

end

def upload_file_to_s3(pack_name, file, file_name, connection)
	s3_key = 'packages/' + pack_name + '/' + file_name
	s3_object = connection.upload(file[:tempfile].path, s3_key, :public_read, file[:type])
	if s3_object != nil && s3_object.public_url != nil
		return true
	else
		return false
	end
	FileUtils.rm(file[:tempfile].path)
end

def upload_filepath_to_s3(pack_name,file_path, file_name, content_type, connection)
	s3_key = 'packages/' + pack_name + '/' + file_name
	s3_object = connection.upload(file_path, s3_key, :public_read, content_type)
	if s3_object != nil && s3_object.public_url != nil
		return true
	else
		return false
	end
	FileUtils.rm(file[:tempfile].path)
end

def make_icon_name(icon_name, ext, update, isEmuticon)
	filename = icon_name + ext
	if update
		filename = update_version_number(filename, isEmuticon)
	end
	return filename
end

def update_version_number(filename, isEmuticon)
	endchar = '.'
	versionChar = '_v'
	if isEmuticon
		versionChar = '-v'
	end
	if filename.include? "@"
		endchar = '@'
	end
	if filename.rindex(versionChar) != nil
		version = filename[filename.rindex(versionChar).. filename.rindex(endchar)-1]
		version_number = filename[filename.rindex(versionChar)+2.. filename.rindex(endchar)-1]
		version_number = version_number.to_i + 1
		filename[version] = versionChar + version_number.to_s
	else
		filename[filename.rindex(endchar)] = versionChar + "1" + endchar
	end

	return filename
end

def reconnect_database(database)
	if MongoMapper.connection.db().name != database.db().name then
	    MongoMapper.connection = database
	    MongoMapper.database = database.db().name
  	end
end
