# LOGIC
require_relative '../model/emuticon'
require_relative '../model/package'
require_relative '../../utils/aws/aws_manager'
require 'byebug'

def getEmuticonByName(package_name,name)
	package = getPackageByName(package_name)
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

def addEmuticon(package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,palette,patched_on,tags,use_for_preview)
	package = getPackageByName(package_name)
	if(source_back_layer != nil)
		# only update mongo if file was uploaded successfully
		filename = make_icon_name(package.name + "-" + name + "-bg", File.extname(source_back_layer[:filename]), false)
		if upload_file_to_s3(package.name,source_back_layer, filename)
			source_back_layer = filename
		end
	end
	if(source_front_layer != nil)
		# only update mongo if file was uploaded successfully
		filename = make_icon_name(package.name + "-" + name + "-fg", File.extname(source_front_layer[:filename]), false)
		if upload_file_to_s3(package.name,source_front_layer,filename)
			source_front_layer = filename
		end
	end
	if(source_user_layer_mask != nil)
		# only update mongo if file was uploaded successfully
		filename = make_icon_name(package.name + "-" + name + "-mask", File.extname(source_user_layer_mask[:filename]), false)
		if upload_file_to_s3(package.name,source_user_layer_mask, filename)
			source_user_layer_mask = filename
		end
	end

	package.emuticons << Emuticon.new(:name => name, :source_back_layer => source_back_layer, :source_front_layer =>
				source_front_layer, :source_user_layer_mask => source_user_layer_mask, :palette => palette, :patchedOn => patched_on,
				:tags => tags, :use_for_preview => use_for_preview)
	package.save
end

def removeEmuticon(package_name,name)
	package = getPackageByName(package_name)
	package.emuticons.delete_if {|emuticon| emuticon.name == name}
	package.save
end

def updateEmuticon(package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,palette,patched_on,tags,use_for_preview)
	package = getPackageByName(package_name)
	emuticon = getEmuticonByName(package_name,name)
	if emuticon != nil
		if(source_back_layer != nil)
			# TODO: make icon name come from mongo
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(emuticon.source_back_layer.rpartition('.').first, File.extname(source_back_layer[:filename]), true)
			if upload_file_to_s3(package.name,source_back_layer, filename)
				emuticon.source_back_layer = filename
			end
		end
		if(source_front_layer != nil)
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(emuticon.source_front_layer.rpartition('.').first, File.extname(source_front_layer[:filename]), true)
			if upload_file_to_s3(package.name,source_front_layer,filename)
				emuticon.source_front_layer = filename
			end
		end
		if(source_user_layer_mask != nil)
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(emuticon.source_user_layer_mask.rpartition('.').first, File.extname(source_user_layer_mask[:filename]), true)
			if upload_file_to_s3(package.name,source_user_layer_mask, filename)
				emuticon.source_user_layer_mask = filename
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
		addEmuticon(package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,palette,patched_on,tags,use_for_preview)
	end
end