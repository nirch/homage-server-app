# LOGIC
require_relative '../model/package'
require_relative 'helper'
require_relative '../../utils/aws/aws_manager'
require 'byebug'

def getPackageById(package_id)
	Package.find_by_id(package_id)
end

def getPackageByName(package_name)
	package = Package.find_by_name(package_name)
	return package
end

def get_all_packages(database)
	reconnect_database(database)
	return Package.all
end

def createNewPackage(name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icon_2x,icon_3x)
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
		emuticons_defaults_hash["source_user_layer_mask"] = name +"-mask" + File.extname(source_user_layer_mask[:filename])
	end
	if active == nil
		active = true
	else
		if(active == "true")
			active = true
		elsif active == "false"
			active = false
		end
	end
	if dev_only == nil
		dev_only = false
	else
		if(dev_only == "true")
			dev_only = true
		elsif dev_only == "false"
			dev_only = false
		end
	end

	icon_name = name + "_icon"
	first_published_on = nil
	meta_data_created_on = Time.now
	meta_data_last_update = nil
	last_update = nil

	package = Package.create({ 
		:first_published_on => first_published_on, :meta_data_created_on => meta_data_created_on,
	 :meta_data_last_update => meta_data_last_update, :last_update => last_update, 
	 :icon_name => icon_name, :name  => name, :label => label, :active => active,  
	 :dev_only => dev_only, :emuticons_defaults => emuticons_defaults_hash })

	if icon_2x != nil
		filename = make_icon_name(icon_name + "@2x", File.extname(icon_2x[:filename]), false, false)
		upload_file_to_s3(package.name, icon_2x, filename)
	end

	if icon_3x != nil
		filename = make_icon_name(icon_name + "@3x", File.extname(icon_3x[:filename]), false, false)
		upload_file_to_s3(package.name, icon_3x, filename)
	end

	if source_user_layer_mask != nil
		filename = make_icon_name(name + "-mask", File.extname(source_user_layer_mask[:filename]), false, false)
		upload_file_to_s3(package.name, source_user_layer_mask, filename)
	end

	return package.id
end

def updatePackage(name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icon_2x,icon_3x)
	package = getPackageByName(name)

	updateResources = false
	
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
	if active != nil
		if(active == "true")
			package.emuticons_defaults["active"] = true
		elsif active == "false"
			package.emuticons_defaults["active"] = false
		end
	end
	if dev_only != nil
		if(dev_only == "true")
			package.emuticons_defaults["dev_only"] = true
		elsif dev_only == "false"
			package.emuticons_defaults["dev_only"] = false
		end
	end

	package.meta_data_last_update = Time.now

	icon_name = package.icon_name

	if icon_2x != nil
		filename = make_icon_name(icon_name + "@2x", File.extname(icon_2x[:filename]), true, false)
		upload_file_to_s3(package.name, icon_2x, filename)
		package.icon_name = filename.rpartition('@').first
		updateResources = true
	end

	if icon_3x != nil
		filename = make_icon_name(icon_name + "@3x", File.extname(icon_3x[:filename]), true, false)
		upload_file_to_s3(package.name, icon_3x, filename)
		package.icon_name = filename.rpartition('@').first
		updateResources = true
	end

	if source_user_layer_mask != nil
		filename = make_icon_name(name + "-mask", File.extname(source_user_layer_mask[:filename]), true, false)
		upload_file_to_s3(package.name, source_user_layer_mask, filename)
		package.emuticons_defaults["source_user_layer_mask"] = filename
		updateResources = true
	end

	last_update = nil
	if updateResources
		last_update = Time.now
	end

	package.save
end