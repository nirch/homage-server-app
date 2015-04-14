# LOGIC
require_relative '../model/emuticon'
require_relative '../model/package'
require_relative '../../utils/aws/aws_manager'
require_relative 'helper'
require 'byebug'

def getEmuticonByName(package_name,name)
	package = getPackageByName(package_name)
	emuticons = package.emuticons

	for emuticon in emuticons
		if emuticon.name == name
			return emuticon
		end
	end
	
	return nil
end

def setUseForPreviewEmuticon(package_name, emuticon_name)
	package = getPackageByName(package_name)
	emuticons = package.emuticons
	for emu in emuticons
		if emu.name != emuticon_name
			emu.use_for_preview = false
			emu.save
		end
	end
end

def addEmuticon(package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,palette,tags,use_for_preview)

	if(use_for_preview == "true")
		setUseForPreviewEmuticon(package_name, name)
	end

	package = getPackageByName(package_name)
	emuticon = getEmuticonByName(package_name,name)
	if emuticon == nil
		if(source_back_layer != nil)
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(package.name + "-" + name + "-bg", File.extname(source_back_layer[:filename]), false, true)
			if upload_file_to_s3(package.name,source_back_layer, filename)
				source_back_layer = filename
			end
		end
		if(source_front_layer != nil)
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(package.name + "-" + name + "-fg", File.extname(source_front_layer[:filename]), false, true)
			if upload_file_to_s3(package.name,source_front_layer,filename)
				source_front_layer = filename
			end
		end
		if(source_user_layer_mask != nil)
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(package.name + "-" + name + "-mask", File.extname(source_user_layer_mask[:filename]), false, true)
			if upload_file_to_s3(package.name,source_user_layer_mask, filename)
				source_user_layer_mask = filename
			end
		end

		if(!palette || palette == "")
			palette = nil
		end

		patched_on = nil

		if(use_for_preview != nil)
			if(use_for_preview == "true")
				use_for_preview = true
			elsif use_for_preview == "false"
				use_for_preview = false
			end
		end

		package.emuticons << Emuticon.new(:name => name, :source_back_layer => source_back_layer, :source_front_layer =>
					source_front_layer, :source_user_layer_mask => source_user_layer_mask, :palette => palette, :patchedOn => patched_on,
					:tags => tags, :use_for_preview => use_for_preview)
		package.save
	end
end

def removeEmuticon(package_name,name)
	package = getPackageByName(package_name)
	package.emuticons.delete_if {|emuticon| emuticon.name == name}
	package.save
end

def updateEmuticon(package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,palette,tags,use_for_preview)

	if(use_for_preview == "true")
		setUseForPreviewEmuticon(package_name, name)
	end

	package = getPackageByName(package_name)
	emuticon = getEmuticonByName(package_name,name)

	if emuticon != nil

		patched = false

		if(source_back_layer != nil)
			# TODO: make icon name come from mongo
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(emuticon.source_back_layer.rpartition('.').first, File.extname(source_back_layer[:filename]), true, true)
			if upload_file_to_s3(package.name,source_back_layer, filename)
				emuticon.source_back_layer = filename
				patched = true
			end
		end
		if(source_front_layer != nil)
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(emuticon.source_front_layer.rpartition('.').first, File.extname(source_front_layer[:filename]), true, true)
			if upload_file_to_s3(package.name,source_front_layer,filename)
				emuticon.source_front_layer = filename
				patched = true
			end
		end
		if(source_user_layer_mask != nil)
			# only update mongo if file was uploaded successfully
			filename = make_icon_name(emuticon.source_user_layer_mask.rpartition('.').first, File.extname(source_user_layer_mask[:filename]), true, true)
			if upload_file_to_s3(package.name,source_user_layer_mask, filename)
				emuticon.source_user_layer_mask = filename
				patched = true
			end
		end
		if(palette != nil)
			emuticon.palette = palette
		end
		if(patched)
			emuticon.patchedOn = Time.now
		end
		if(tags != nil)
			emuticon.tags = tags
		end
		if(use_for_preview != nil)
			if(use_for_preview == "true")
				emuticon.use_for_preview = true
			elsif use_for_preview == "false"
				emuticon.use_for_preview = false
			end
		end

		emuticon.save
	end
end