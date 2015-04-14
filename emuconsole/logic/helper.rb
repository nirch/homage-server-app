require_relative '../../utils/aws/aws_manager'

def upload_file_to_s3(pack_name, file, file_name)
	s3_key = 'packages/' + pack_name + '/' + file_name
	s3_object = settings.emu_s3_test.upload(file[:tempfile].path, s3_key, :public_read, file[:type])
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
