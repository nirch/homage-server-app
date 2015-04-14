require_relative '../utils/aws/aws_manager'
require_relative '../utils/zipper'
require_relative 'logic/emuticon'
require_relative 'logic/package'
require_relative 'logic/helper'
require 'fileutils'

# Main file
def deployEmuPackage(package_name)


	download_folder = "downloadTemp/"
	FileUtils::mkdir_p download_folder

	scratchpad_package = getPackageByName(package_name)

	input_files = getResourcesFromPackage(scratchpad_package)

	# THE DOWNLOAD FROM SCRATCHPAD

	download_from_aws(package_name, input_files, download_folder, settings.emu_s3_test)
	download_zip_from_s3(download_folder, scratchpad_package.cms_last_zip_file_name, settings.emu_s3_test)
	# TODO downloadzip

	# THE UPLOAD TO PRODUCTION

	# create package on the production db and save first_published_on to now
	reconnect_database(settings.emu_public)

	production_package = getPackageByName(package_name)
	if production_package != nil
		production_package.delete
	end

	production_package = Package.create({ 
		:first_published_on => Time.now, :meta_data_created_on => scratchpad_package.meta_data_created_on,
	 	:meta_data_last_update => scratchpad_package.meta_data_last_update, :last_update => scratchpad_package.last_update,
	 	:name => scratchpad_package.name, :cms_last_zip_file_name => scratchpad_package.cms_last_zip_file_name,
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
			:palette => emuticon.palette, 
			:patchedOn => emuticon.patchedOn,
			:tags => emuticon.tags, 
			:use_for_preview => emuticon.use_for_preview)

	end
	production_package.save

	# Upload All package and emuticon files and latest zip file

	upload_to_aws(package_name, input_files, download_folder, settings.emu_s3_prod)
	upload_zip_to_s3(download_folder, production_package.cms_last_zip_file_name, settings.emu_s3_prod)

	# FINISH HIM

	delete_download_folder(download_folder)
	
end

