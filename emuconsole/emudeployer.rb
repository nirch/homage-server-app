require_relative '../utils/aws/aws_manager'
require_relative '../utils/zipper'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require_relative 'logic/helper'
require 'fileutils'
require 'time'

# Main file
def deployEmuPackage(package_name)

	package = getPackageByName(package_name, settings.emu_scratchpad)
	package.cms_proccessing = true
	package.save

	begin
		success = true
		message = "start"

		download_folder = "downloadTemp/"
		FileUtils::mkdir_p download_folder

		production_package = getPackageByName(package_name, settings.emu_public)
		scratchpad_package = getPackageByName(package_name, settings.emu_scratchpad)
		message = "input_files"
		input_files = getResourcesFromPackage(scratchpad_package.name, true, message)

		# THE DOWNLOAD FROM SCRATCHPAD
		message = "download_from_aws"
		success = download_from_aws(package_name, input_files, download_folder, settings.emu_s3_test)

		if(success == true)
			message = "download_zip_from_s3"
			if(production_package == nil || (production_package != nil && scratchpad_package.zipped_package_file_name != production_package.zipped_package_file_name))
				success = download_zip_from_s3(download_folder, scratchpad_package.zipped_package_file_name, settings.emu_s3_test)
			end
		end
		# TODO downloadzip

		# THE UPLOAD TO PRODUCTION
		if(success == true)
			# create package on the production db and save first_published_on to now
			reconnect_database(settings.emu_public)

			# Upload All package and emuticon files and latest zip file
			if(success == true)
				message = "upload_to_aws"
				success = upload_to_aws(package_name, input_files, download_folder, settings.emu_s3_prod)
			end
			if(success == true)
				message = "upload_zip_to_s3"
				if(production_package == nil || (production_package != nil && scratchpad_package.zipped_package_file_name != production_package.zipped_package_file_name))
					success = upload_zip_to_s3(download_folder, scratchpad_package.zipped_package_file_name, settings.emu_s3_prod)
				end
			end

			if (success == true)
				if(production_package != nil)
					# UPDATE package
					updatePackageOnProduction(production_package, scratchpad_package)

				else
					# CREATE NEW PACKAGE
					createPackageOnProduction(production_package, scratchpad_package)

				end
			end

		end

		# FINISH HIM
		message = "delete_download_folder.save"
		delete_download_folder(download_folder)

		return success

	rescue StandardError => e

		return "deployEmuPackage: " + message + " error: " + e.to_s

	ensure
		package = getPackageByName(package_name, settings.emu_scratchpad)
		package.cms_proccessing = false
		package.save
	end
	
end

def updatePackageOnProduction(production_package, scratchpad_package)
	currenttime = Time.now.utc.iso8601

	if (scratchpad_package.first_published_on != nil)
		if(production_package.first_published_on == nil)
			production_package.first_published_on = currenttime
		end
	else (production_package.first_published_on != nil)
		production_package.first_published_on = nil
	end

	if(production_package.cms_first_published == nil)
		production_package.cms_first_published = currenttime
	end

	if (scratchpad_package.notification_text != nil)
		production_package.notification_text = scratchpad_package.notification_text
	elsif production_package.notification_text != nil
		production_package.notification_text = nil
	end

	if (scratchpad_package.meta_data_last_update != nil)
		production_package.meta_data_last_update = scratchpad_package.meta_data_last_update
	elsif production_package.meta_data_last_update != nil
		production_package.meta_data_last_update = nil
	end

	if (scratchpad_package.last_update != nil)
		production_package.last_update = scratchpad_package.last_update
	end

	if (scratchpad_package.zipped_package_file_name != nil)
		production_package.zipped_package_file_name = scratchpad_package.zipped_package_file_name
	end

	if (scratchpad_package.icon_name != nil)
		production_package.icon_name = scratchpad_package.icon_name
	end

	if (scratchpad_package.cms_icon_2x != nil)
		production_package.cms_icon_2x = scratchpad_package.cms_icon_2x
	end

	if (scratchpad_package.cms_icon_3x != nil)
		production_package.cms_icon_3x = scratchpad_package.cms_icon_3x
	end

	if (scratchpad_package.label != nil)
		production_package.label = scratchpad_package.label
	end

	if (scratchpad_package.active != nil)
		production_package.active = scratchpad_package.active
	end

	if (scratchpad_package.dev_only != nil)
		production_package.dev_only = scratchpad_package.dev_only
	end

	production_package.emuticons_defaults = scratchpad_package.emuticons_defaults

	production_package.emuticons = scratchpad_package.emuticons

	production_package.cms_last_published = currenttime

	message = "production_package.save"
	production_package.save

end

def createPackageOnProduction(production_package, scratchpad_package)
	currenttime = Time.now.utc.iso8601
	first_published_on = nil
	if (scratchpad_package.first_published_on != nil)
		first_published_on = currenttime
	end

	production_package = Package.create({ :id => scratchpad_package.id,
	:cms_first_published => currenttime, :cms_last_published => currenttime,
	:first_published_on => first_published_on,:notification_text => scratchpad_package.notification_text, 
	:meta_data_created_on => scratchpad_package.meta_data_created_on,
 	:meta_data_last_update => scratchpad_package.meta_data_last_update, :last_update => scratchpad_package.last_update,
 	:name => scratchpad_package.name, :zipped_package_file_name => scratchpad_package.zipped_package_file_name,
 	:icon_name => scratchpad_package.icon_name, :cms_icon_2x => scratchpad_package.cms_icon_2x,
  	:cms_icon_3x => scratchpad_package.cms_icon_3x, :label => scratchpad_package.label,
    :active => scratchpad_package.active,  
 	:dev_only => scratchpad_package.dev_only, :emuticons_defaults => scratchpad_package.emuticons_defaults })

	# Create emuticons

	for emuticon in scratchpad_package.emuticons do

		production_package.emuticons << Emuticon.new(
			:name => emuticon.name, 
			:source_back_layer => emuticon.source_back_layer, 
			:source_front_layer => emuticon.source_front_layer,
			:source_user_layer_mask => emuticon.source_user_layer_mask,
			:duration => emuticon.duration, 
			:frames_count => emuticon.frames_count, 
			:thumbnail_frame_index => emuticon.thumbnail_frame_index, 
			:palette => emuticon.palette, 
			:patched_on => emuticon.patched_on,
			:tags => emuticon.tags, 
			:use_for_preview => emuticon.use_for_preview)

	end
	message = "production_package.save"
	production_package.save
end

