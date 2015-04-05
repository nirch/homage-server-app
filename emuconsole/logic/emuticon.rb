# LOGIC
require_relative '../model/emuticon'
require_relative '../model/package'
require_relative '../../utils/aws/aws_manager'
require 'byebug'

def getEmuticonByName(package_id,name)
	package = getPackageById(package_id)
	emuticons = package.emuticons
	for emuticon in emuticons
		if emuticon.name == name
			return emuticon
		end
	end
	if emuticon != nil
		return emuticon
	else
		return nil
	end
end

def addEmuticon(package_id,name,source_back_layer,source_back_layer_filepath,source_front_layer,source_front_layer_filepath,source_user_layer_mask,source_user_layer_mask_filepath,palette,patched_on,tags,use_for_preview)
	package = getPackageById(package_id)

	if source_back_layer != nil
		if upload_gif(package.name, source_back_layer, source_back_layer_filepath, "image/gif")
			# Success
		else
			# do not fill in this layer because the object wasn't uploaded successfully
			source_back_layer = nil
		end
	end
	if source_front_layer != nil
		if upload_gif(package.name,source_front_layer, source_front_layer_filepath, "image/gif")
			# Success
		else
			# do not fill in this layer because the object wasn't uploaded successfully
			source_front_layer = nil
		end
	end
	if source_user_layer_mask != nil
		if upload_gif(package.name,source_user_layer_mask, source_user_layer_mask_filepath, "image/jpeg")
			# Success
		else
			# do not fill in this layer because the object wasn't uploaded successfully
			source_user_layer_mask = nil
		end
	end

	package.emuticons << Emuticon.new(:name => name, :source_back_layer => source_back_layer, :source_front_layer =>
				source_front_layer, :source_user_layer_mask => source_user_layer_mask, :palette => palette, :patchedOn => patched_on,
				:tags => tags, :use_for_preview => use_for_preview)
	package.save
end

def removeEmuticon(package_id,name)
	package = getPackageById(package_id)
	package.emuticons.delete_if {|emuticon| emuticon.name == name}
	package.save
end

def updateEmuticon(package_id,name,source_back_layer,source_back_layer_filepath,source_front_layer,source_front_layer_filepath,source_user_layer_mask,source_user_layer_mask_filepath,palette,patched_on,tags,use_for_preview)
	emuticon = getEmuticonByName(package_id,name)
	if emuticon != nil
		if(source_back_layer != nil)
			# only update mongo if file was uploaded successfully
			if upload_gif(package.name,source_back_layer, source_back_layer_filepath, "image/gif")
				emuticon.source_back_layer = source_back_layer
			end
		end
		if(source_front_layer != nil)
			# only update mongo if file was uploaded successfully
			if upload_gif(package.name,source_front_layer, source_front_layer_filepath, "image/gif")
				emuticon.source_front_layer = source_front_layer
			end
		end
		if(source_user_layer_mask != nil)
			# only update mongo if file was uploaded successfully
			if upload_gif(package.name,source_user_layer_mask, source_user_layer_mask_filepath, "image/jpeg")
				emuticon.source_user_layer_mask = source_user_layer_mask
			end
		end
		if(palette != nil)
			emuticon.palette = palette
		end
		if(patched_on != nil)
			emuticon.patchedOn = patched_on
		end
		if(tags != nil)
			emuticon.tags = tags
		end
		if(use_for_preview != nil)
			emuticon.use_for_preview = use_for_preview
		end
		emuticon.save
	else
		addEmuticon(package_id,name,source_back_layer,source_front_layer,source_user_layer_mask)
	end
end

def upload_gif(pack_name, gif_name, filepath, content_type)
	s3_key = 'packages/' + pack_name + '/' + gif_name
	s3_object = settings.emu_s3_test.upload(filepath, s3_key, :public_read, content_type)
	if s3_object != nil && s3_object.public_url != nil
		return true
	else
		return false
	end
end