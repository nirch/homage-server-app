# LOGIC
require_relative '../model/package'
require_relative 'helper'
require_relative '../../utils/aws/aws_manager'
require 'time'

def getPackageById(package_id, connection)
	reconnect_database(connection)
	Package.find_by_id(package_id)
	return package
end

def getPackageByName(package_name, connection)
	reconnect_database(connection)
	package = Package.find_by_name(package_name)
	return package
end

def get_all_packages(connection)
	reconnect_database(connection)
	return Package.sort(:name).all
end

def createNewPackage(mongoconnection, awsconnection, name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,active,dev_only,icon_2x,icon_3x,first_published_on, notification_text)
	
	success = true

	begin

		emuticons_defaults_hash = Hash.new("emuticons_defaults")
		if duration != nil
			emuticons_defaults_hash["duration"] = duration.to_i
		end
		if frames_count != nil
			emuticons_defaults_hash["frames_count"] = frames_count.to_i
		end
		if thumbnail_frame_index != nil
			emuticons_defaults_hash["thumbnail_frame_index"] = thumbnail_frame_index.to_i
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
		meta_data_created_on = Time.now.utc.iso8601
		meta_data_last_update = nil
		last_update = nil

		icon2xName = ""
		if icon_2x != nil
			filename = make_icon_name(icon_name + "@2x", File.extname(icon_2x[:filename]), false, false)
			success = upload_file_to_s3(name, icon_2x, filename, awsconnection)
			icon2xName = filename
		end

		if(success != true)
			return success
		end

		icon3xName = ""
		if icon_3x != nil
			filename = make_icon_name(icon_name + "@3x", File.extname(icon_3x[:filename]), false, false)
			success = upload_file_to_s3(name, icon_3x, filename, awsconnection)
			icon3xName = filename
		end

		if(success != true)
			return success
		end

		if source_user_layer_mask != nil
			filename = make_icon_name(name + "-mask", File.extname(source_user_layer_mask[:filename]), false, false)
			success = upload_file_to_s3(name, source_user_layer_mask, filename, awsconnection)
		end

		if(success != true)
			return success
		end

		if(first_published_on != "false")
				first_published_on = Time.now.utc.iso8601
		else
			first_published_on = nil
		end

		package = Package.create({ 
			:first_published_on => first_published_on,
			:data_update_time_stamp => meta_data_created_on.to_time.to_i,
			:meta_data_created_on => meta_data_created_on, 
			:notification_text => notification_text,
		 	:meta_data_last_update => meta_data_last_update, 
		 	:last_update => last_update,
		 	:name => name, 
		 	:icon_name => icon_name, 
		 	:cms_icon_2x => icon2xName, 
		 	:cms_icon_3x => icon3xName, 
		 	:cms_state => "save",
		 	:label => label, 
		 	:active => active, 
		 	:dev_only => dev_only, 
		 	:emuticons_defaults => emuticons_defaults_hash 
		 	})

		if(package == nil)
			success = "Problem creating package: " + find_by_name
		end

		return success

	rescue StandardError => e

		return "createNewPackage" + e.to_s

	ensure
	end
end

def updatePackage(mongoconnection,awsconnection, name,label,duration,frames_count,thumbnail_frame_index,source_user_layer_mask,removesource_user_layer_mask,active,dev_only,icon_2x,icon_3x, first_published_on, notification_text)
	success = true
	production_package = getPackageByName(name,settings.emu_public)
	package = getPackageByName(name,mongoconnection)
	package.cms_proccessing = true
	package.save

	currenttime = Time.now.utc.iso8601

	begin
		package = getPackageByName(name,mongoconnection)

		updateResources = false
		
		if label != nil
			package.label = label
		end
		if duration != nil
			package.emuticons_defaults["duration"] = duration.to_i
		end
		if frames_count != nil
			package.emuticons_defaults["frames_count"] = frames_count.to_i
		end
		if thumbnail_frame_index != nil
			package.emuticons_defaults["thumbnail_frame_index"] = thumbnail_frame_index.to_i
		end
		if notification_text != nil
			package.notification_text = notification_text
		elsif package.notification_text != nil
			package.notification_text = nil
		end
		if active != nil
			if(active == "true")
				package.active = true
			elsif active == "false"
				package.active = false
			end
		end
		if dev_only != nil
			if(dev_only == "true")
				package.dev_only = true
			elsif dev_only == "false"
				package.dev_only = false
			end
		end

		package.meta_data_last_update = currenttime
		package.data_update_time_stamp = currenttime.to_time.to_i
		icon_name = package.icon_name
		if icon_2x != nil
			filename = make_icon_name(icon_name + "@2x", File.extname(icon_2x[:filename]), true, false)
			upload_file_to_s3(package.name, icon_2x, filename, awsconnection)
			package.icon_name = filename.rpartition('@').first
			package.cms_icon_2x = filename
		elsif package.cms_icon_2x == nil
			filename = make_icon_name(icon_name + "@2x", ".png", false, false)
			package.icon_name = filename.rpartition('@').first
			package.cms_icon_2x = filename
		end

		if icon_3x != nil
			filename = make_icon_name(icon_name + "@3x", File.extname(icon_3x[:filename]), true, false)
			upload_file_to_s3(package.name, icon_3x, filename, awsconnection)
			package.icon_name = filename.rpartition('@').first
			package.cms_icon_3x = filename
		elsif package.cms_icon_3x == nil
			filename = make_icon_name(icon_name + "@3x", ".png", false, false)
			package.icon_name = filename.rpartition('@').first
			package.cms_icon_3x = filename
		end

		if source_user_layer_mask != nil
			filename = make_icon_name(name + "-mask", File.extname(source_user_layer_mask[:filename]), true, false)
			upload_file_to_s3(package.name, source_user_layer_mask, filename, awsconnection)
			package.emuticons_defaults["source_user_layer_mask"] = filename
			updateResources = true
		elsif package.emuticons_defaults["source_user_layer_mask"] != nil  && removesource_user_layer_mask == "true"
			package.emuticons_defaults["source_user_layer_mask"] = nil
			updateResources = true
		end

		if package.zipped_package_file_name == nil && package.last_update != nil
			zip_file_name = create_zip_file_name(package.name, package.last_update.iso8601)
			package.zipped_package_file_name = zip_file_name + ".zip"
		end

		if (updateResources == true && package.emuticons.length >= 6)
			package.cms_state = "zip"
		end

		
		if(first_published_on == "true" || first_published_on == "on")
			if(production_package != nil && production_package.first_published_on != nil)
				package.first_published_on = production_package.first_published_on
			else
				package.first_published_on = currenttime
			end
		elsif package.first_published_on != nil
			package.first_published_on = nil
		end
		

		if(production_package != nil && production_package.cms_first_published != nil)
			package.cms_first_published = production_package.cms_first_published
		end

		package.save

		return success

	rescue StandardError => e

		return "updatePackage: " + e.to_s

	ensure
		package = getPackageByName(name,mongoconnection)
		package.cms_proccessing = false
		package.save
	end

end