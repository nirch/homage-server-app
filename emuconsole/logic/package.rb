# LOGIC
require_relative '../model/package'
require_relative '../../utils/aws/aws_manager'

def getPackageById(package_id)
	Package.find_by_id(package_id)
end

def getPackageByName(package_name)
	package = Package.find_by_name(package_name)
	return package
end

def createNewPackage(first_published_on,last_update,name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icons_files_list)
	emuticons_defaults_hash = Hash.new("emuticons_defaults")
	if duration != nil
		emuticons_defaults_hash["duration"] = duration
	else
		emuticons_defaults_hash["duration"] = 2
	end
	if frames_count != nil
		emuticons_defaults_hash["frames_count"] = frames_count
	else
		emuticons_defaults_hash["frames_count"] = 24
	end
	if thumbnail_frame_index != nil
		emuticons_defaults_hash["thumbnail_frame_index"] = thumbnail_frame_index
	else
		emuticons_defaults_hash["thumbnail_frame_index"] = 23
	end
	if source_user_layer_mask != nil
		emuticons_defaults_hash["source_user_layer_mask"] = name +"-mask.jpg"
	end
	if active == nil
		active = true
	end
	if dev_only == nil
		dev_only = false
	end

	icon_name = name + "_icon"

	package = Package.create({    :first_published_on => first_published_on, :created_at => Time.now, :last_update =>
	last_update, :icon_name => icon_name, :name  => name, :label => label, :active => active,  :dev_only =>
	dev_only, :emuticons_defaults => emuticons_defaults_hash })

	if icons_files_list != nil
		for icon_hash in icons_files_list
			# Upload to S3
			upload_icon(package.name, icon_hash["filename"], icon_hash["filepath"], "image/png")
		end
	end
	return package.id
end

def updatePackage(first_published_on,last_update,name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icons_files_list)

	package = getPackageByName(name)
	if first_published_on != nil
		package.first_published_on = first_published_on
	end
	if last_update != nil
		package.last_update = last_update
	end
	if name != nil
		package.name = name
	end
	if label != nil
		package.label = label
	end
	if duration != nil
		package.emuticons_defaults["duration"] = duration
	end
	if frames_count != nil
		package.emuticons_defaults["frames_count"] = frames_count
	end
	if thumbnail_frame_index != nil
		package.emuticons_defaults["thumbnail_frame_index"] = thumbnail_frame_index
	end
	if source_user_layer_mask != nil
		package.emuticons_defaults["source_user_layer_mask"] = source_user_layer_mask
	end
	if active != nil
		package.emuticons_defaults["active"] = active
	end
	if dev_only != nil
		package.emuticons_defaults["dev_only"] = dev_only
	end

	icon_name = name + "_icon"

	if icons_files_list != nil
		for icon_hash in icons_files_list
			upload_icon(package.name, icon_hash["filename"], icon_hash["filepath"],"image/png")
		end
	end
	package.save
end

def upload_icon(pack_name, filename, filepath, content_type)
	s3_key = 'packages/' + pack_name + '/' + filename
	s3_object = settings.emu_s3_test.upload(filepath, s3_key, :public_read, content_type)
	if s3_object != nil && s3_object.public_url != nil
		return true
	else
		return false
	end
end