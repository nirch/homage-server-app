require_relative '../../utils/aws/aws_manager'
require_relative '../model/emuticon'
require_relative '../model/package'
require_relative '../../utils/zipper'

# Zip File Name
def create_zip_file_name(package_name, currentdatetime)
	return "package_" + package_name + "_" + ("%02d" % Time.parse(currentdatetime).year).to_s + ("%02d" % Time.parse(currentdatetime).month).to_s + ("%02d" % Time.parse(currentdatetime).day).to_s + "_" + ("%02d" % Time.parse(currentdatetime).hour).to_s + ("%02d" % Time.parse(currentdatetime).min).to_s + ("%02d" % Time.parse(currentdatetime).sec).to_s
end

# zip files
def zip_package_files(download_folder, input_filenames, zip_file_name)
	return zipListOfFiles(download_folder, input_filenames, zip_file_name)
end

# upload zip file to zipped_packages
def upload_zip_to_s3(file_path, filename, connection)
	if !filename.include? ".zip"
		filename += ".zip"
	end
	s3_key = "zipped_packages/" + filename
	return connection.upload(file_path + filename, s3_key, :public_read, content_type=nil, metadata=nil)
end

# upload zip file to zipped_packages
def download_zip_from_s3(file_path, filename, connection)
	s3_key = "zipped_packages/" + filename
	success = connection.download(s3_key, file_path + filename)
	return success
end


# delete download folder
def delete_download_folder(folder)
	FileUtils.rm_rf(folder)
end

# get files to download from aws
def getResourcesFromPackage(package_name, getOnlyNew, message, deploy)
	public_package = nil
	if(getOnlyNew)
		public_package = getPackageByName(package_name, settings.emu_public)
	end

	message = "getPackageByName"

	package = getPackageByName(package_name, settings.emu_scratchpad)

	input_files = []

	if deploy
		icon2x = package.cms_icon_2x
		input_files.push icon2x
		icon3x = package.cms_icon_3x
		input_files.push icon3x
	end
	message = "package.emuticons_defaults[]"
	source_user_layer_mask = package.emuticons_defaults["source_user_layer_mask"]
	if source_user_layer_mask != nil && source_user_layer_mask != ""
		insertValue = false
		if public_package != nil
			if public_package.emuticons_defaults["source_user_layer_mask"] == nil
				insertValue = true
			else
				if public_package.emuticons_defaults["source_user_layer_mask"] != source_user_layer_mask
					insertValue = true
				end
			end
		else
			insertValue = true
		end
		if(insertValue)
			input_files.push source_user_layer_mask
		end
	end

	message = "for emuticon in package.emuticons do"
	for emuticon in package.emuticons do
		public_emuticon = nil
		if(public_package != nil)
			public_emuticon = getEmuticonByName(settings.emu_public, package_name,emuticon.name)
		end
		message = "source_back_layer = emuticon.source_back_layer"
		source_back_layer = emuticon.source_back_layer
		if source_back_layer != nil && source_back_layer != ""
			insertValue = false
			if public_emuticon != nil
				if public_emuticon.source_back_layer == nil
					insertValue = true
				else
					if public_emuticon.source_back_layer != source_back_layer
						insertValue = true
					end
				end
			else
				insertValue = true
			end
			if(insertValue)
				input_files.push source_back_layer
			end
		end

		message = "source_front_layer = emuticon.source_front_layer"
		source_front_layer = emuticon.source_front_layer
		if source_front_layer != nil && source_front_layer != ""

			insertValue = false
			if public_emuticon != nil
				if public_emuticon.source_front_layer == nil
					insertValue = true
				else
					if public_emuticon.source_front_layer != source_front_layer
						insertValue = true
					end
				end
			else
				insertValue = true
			end
			if(insertValue)
				input_files.push source_front_layer
			end
		end

		message = "source_user_layer_mask = emuticon.source_user_layer_mask"
		source_user_layer_mask = emuticon.source_user_layer_mask
		if source_user_layer_mask != nil && source_user_layer_mask != ""
			insertValue = false
			if public_emuticon != nil
				if public_emuticon.source_user_layer_mask == nil
					insertValue = true
				else
					if public_emuticon.source_user_layer_mask != source_user_layer_mask
						insertValue = true
					end
				end
			else
				insertValue = true
			end
			if(insertValue)
				input_files.push source_user_layer_mask
			end
		end
	end

	return input_files
end

# download files
def download_from_aws(package_name, input_files, download_folder, connection)

	success = true

	for f in input_files do
		if(f != nil)
			filename = package_name + "/" + f
			object_key = "packages/" + filename
			local_path = download_folder + f
			success = connection.download(object_key, local_path)
			if(success != true)
				return "Problem downloading: " + f
			end
		end
	end

	return success

end

# upload files
def upload_to_aws(package_name, input_files, download_folder, connection)
	success = true

	for f in input_files do
		local_path = download_folder + f
		success = upload_filepath_to_s3(package_name,local_path, f, "image/*", connection)
		if(success != true)
			return "Problem uploading: " + f
		end
	end
	
	return success
end

def upload_file_to_s3(pack_name, file, file_name, connection)
	s3_key = 'packages/' + pack_name + '/' + file_name
	success =  connection.upload(file[:tempfile].path, s3_key, :public_read, file[:type])
	# if s3_object != nil && s3_object.public_url != nil
	# 	return true
	# else
	# 	return false
	# end
	FileUtils.rm(file[:tempfile].path)
	return success
end

def upload_filepath_to_s3(pack_name,file_path, file_name, content_type, connection)
	s3_key = 'packages/' + pack_name + '/' + file_name
	success = connection.upload(file_path, s3_key, :public_read, content_type)
	# if s3_object != nil && s3_object.public_url != nil
	# 	return true
	# else
	# 	return false
	# end
	# FileUtils.rm(file[:tempfile].path)

	return success
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
