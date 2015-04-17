# LOGIC
require_relative '../model/package'
require_relative 'helper'
require_relative '../../utils/aws/aws_manager'
require 'time'

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

def createNewPackage(connection, name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icon_2x,icon_3x)
	
	success = true
	package = getPackageByName(package_name)
	package.cms_proccessing = true
	package.save

	begin

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
		meta_data_created_on = Time.now.utc.iso8601
		meta_data_last_update = nil
		last_update = nil

		icon2xName = ""
		if icon_2x != nil
			filename = make_icon_name(icon_name + "@2x", File.extname(icon_2x[:filename]), false, false)
			success = upload_file_to_s3(name, icon_2x, filename, connection)
			icon2xName = filename
		end

		if(success != true)
			return success
		end

		icon3xName = ""
		if icon_3x != nil
			filename = make_icon_name(icon_name + "@3x", File.extname(icon_3x[:filename]), false, false)
			success = upload_file_to_s3(name, icon_3x, filename, connection)
			icon3xName = filename
		end

		if(success != true)
			return success
		end

		if source_user_layer_mask != nil
			filename = make_icon_name(name + "-mask", File.extname(source_user_layer_mask[:filename]), false, false)
			success = upload_file_to_s3(name, source_user_layer_mask, filename, connection)
		end

		if(success != true)
			return success
		end

		package = Package.create({ 
			:first_published_on => first_published_on, :meta_data_created_on => meta_data_created_on,
		 :meta_data_last_update => meta_data_last_update, :last_update => last_update,:name => name, 
		 :icon_name => icon_name, :cms_icon_2x => icon2xName, :cms_icon_3x => icon3xName, :cms_state => "save",
		 :label => label, :active => active, :dev_only => dev_only, :emuticons_defaults => emuticons_defaults_hash })

		if(package == nil)
			success = "Problem creating package: " + find_by_name
		end

		return success

	rescue StandardError => e

		return "createNewPackage" + e.to_s

	ensure
		package = getPackageByName(package_name)
		package.cms_proccessing = false
		package.save
	end
end

def updatePackage(connection, name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icon_2x,icon_3x)
	success = true
	package = getPackageByName(package_name)
	package.cms_proccessing = true
	package.save

	begin

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

		package.meta_data_last_update = Time.now.utc.iso8601

		icon_name = package.icon_name

		if icon_2x != nil
			filename = make_icon_name(icon_name + "@2x", File.extname(icon_2x[:filename]), true, false)
			upload_file_to_s3(package.name, icon_2x, filename, connection)
			package.icon_name = filename.rpartition('@').first
			updateResources = true
			package.cms_icon_2x = filename
		end

		if icon_3x != nil
			filename = make_icon_name(icon_name + "@3x", File.extname(icon_3x[:filename]), true, false)
			upload_file_to_s3(package.name, icon_3x, filename, connection)
			package.icon_name = filename.rpartition('@').first
			updateResources = true
			package.cms_icon_3x = filename
		end

		if source_user_layer_mask != nil
			filename = make_icon_name(name + "-mask", File.extname(source_user_layer_mask[:filename]), true, false)
			upload_file_to_s3(package.name, source_user_layer_mask, filename, connection)
			package.emuticons_defaults["source_user_layer_mask"] = filename
			updateResources = true
		end

		package.save

		return success

	rescue StandardError => e

		return "updatePackage" + e.to_s

	ensure
		package = getPackageByName(package_name)
		package.cms_proccessing = false
		package.save
	end

end