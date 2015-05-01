# LOGIC
require_relative '../model/emuticon'
require_relative '../model/package'
require_relative '../../utils/aws/aws_manager'
require_relative 'helper'
require 'byebug'

def getEmuticonByName(connection, package_name,name)
	package = getPackageByName(package_name,connection)
	emuticons = package.emuticons

	for emuticon in emuticons
		if emuticon.name == name
			return emuticon
		end
	end
	
	return nil
end

def setUseForPreviewEmuticon(connection, package_name, emuticon_name)
	package = getPackageByName(package_name,connection)
	emuticons = package.emuticons
	for emu in emuticons
		if emu.name != emuticon_name

			begin

				id = emu.id
				name = emu.name 
				source_back_layer = emu.source_back_layer 
				source_front_layer = emu.source_front_layer 
				source_user_layer_mask = emu.source_user_layer_mask 
				duration = emu.duration 
				frames_count = emu.frames_count 
				thumbnail_frame_index = emu.thumbnail_frame_index 
				palette = emu.palette 
				patched_on = emu.patched_on 
				tags = emu.tags

				package.emuticons.delete_if {|pemuticon| pemuticon.name == emu.name}
				package.save
				package = getPackageByName(package_name,connection)
				createNewEmuticon(package, id, name, source_back_layer, source_front_layer, source_user_layer_mask, duration, frames_count, thumbnail_frame_index, palette, patched_on, tags, nil)
				package.save

			rescue StandardError => e

				lastemuticon = getEmuticonByName(connection, package_name,emu.name)
				if lastemuticon == nil
					package.emuticons << emu
					package.save
				end

				return " use_for_preview: " + e.to_s

			ensure
				package = getPackageByName(package_name,connection)
				package.cms_proccessing = false
				package.save
			end

		end
	end
end

def createNewEmuticon(package, id, name, source_back_layer, source_front_layer, source_user_layer_mask, duration, frames_count, thumbnail_frame_index, palette, patched_on, tags, use_for_preview)
	package.emuticons << Emuticon.new(:id => id, :name => name, :source_back_layer => source_back_layer, :source_front_layer =>
							source_front_layer, :source_user_layer_mask => source_user_layer_mask,
							:duration => duration, :frames_count => frames_count, :thumbnail_frame_index => thumbnail_frame_index,
							 :palette => palette, :patched_on => patched_on,
							:tags => tags, :use_for_preview => use_for_preview)
end

def addEmuticon(mongoconnection, awsconnection, package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,duration,frames_count,thumbnail_frame_index,palette,tags,use_for_preview)

	success = true
	package = getPackageByName(package_name,mongoconnection)
	package.cms_proccessing = true
	package.save

	begin

		if(use_for_preview == "true")
			setUseForPreviewEmuticon(mongoconnection, package_name, name)
		end

		package = getPackageByName(package_name,mongoconnection)
		emuticon = getEmuticonByName(mongoconnection, package_name,name)
		if emuticon == nil
			if(source_back_layer != nil)
				# only update mongo if file was uploaded successfully
				filename = make_icon_name(nameNewEmuticon(package.name, name, "-bg"), File.extname(source_back_layer[:filename]), false, true)
				success = upload_file_to_s3(package.name,source_back_layer, filename, awsconnection)
				if(success == true)
					source_back_layer = filename
				end
			end
			if(success == true && source_front_layer != nil)
				# only update mongo if file was uploaded successfully
				filename = make_icon_name(nameNewEmuticon(package.name, name, "-fg"), File.extname(source_front_layer[:filename]), false, true)
				success = upload_file_to_s3(package.name,source_front_layer,filename, awsconnection)
				if(success == true)
					source_front_layer = filename
				end
			end
			if(success == true && source_user_layer_mask != nil)
				# only update mongo if file was uploaded successfully
				filename = make_icon_name(nameNewEmuticon(package.name, name, "-mask"), File.extname(source_user_layer_mask[:filename]), false, true)
				success = upload_file_to_s3(package.name,source_user_layer_mask, filename, awsconnection)
				if(success == true)
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
					use_for_preview = nil
				end
			end

			if(success == true)
				createNewEmuticon(package, nil, name, source_back_layer, source_front_layer, source_user_layer_mask, duration, frames_count, thumbnail_frame_index, palette, patched_on, tags, use_for_preview)

				if(package.emuticons.length >= 6)
					package.cms_state = "zip"
				end

				package.save
			end
		end

		return success

	rescue StandardError => e

		return "addEmuticon" + e.to_s

	ensure
		package = getPackageByName(package_name,mongoconnection)
		package.cms_proccessing = false
		package.save
	end
end

def removeEmuticon(mongoconnection, awsconnection, package_name,name)
	package = getPackageByName(package_name,mongoconnection)
	package.emuticons.delete_if {|emuticon| emuticon.name == name}
	package.save
end

def nameNewEmuticon(package_name, name, type)
	return package_name + "-" + name + type
end

def updateEmuticon(mongoconnection, awsconnection, package_name,name,source_back_layer,source_front_layer,source_user_layer_mask,removesource_back_layer,removesource_front_layer,removesource_user_layer_mask,duration,frames_count,thumbnail_frame_index,palette,tags,use_for_preview)

	success = true
	package = getPackageByName(package_name,mongoconnection)
	package.cms_proccessing = true
	package.save

	begin

		if(use_for_preview == "true")
			setUseForPreviewEmuticon(mongoconnection, package_name, name)
		end

		package = getPackageByName(package_name,mongoconnection)
		emuticon = getEmuticonByName(mongoconnection, package_name,name)
		if emuticon != nil

			patched = false
			if(source_back_layer != nil)
				# TODO: make icon name come from mongo
				# only update mongo if file was uploaded successfully
				filename = ""
				if(emuticon.source_back_layer != nil)
					filename = make_icon_name(emuticon.source_back_layer.rpartition('.').first, File.extname(source_back_layer[:filename]), true, true)
				else
					filename = make_icon_name(nameNewEmuticon(package.name, name, "-bg"), File.extname(source_back_layer[:filename]), false, true)
				end
				success = upload_file_to_s3(package.name,source_back_layer, filename, awsconnection)
				if(success == true)
					source_back_layer = filename
					patched = true
				end
			elsif emuticon.source_back_layer != nil && removesource_back_layer == "true"
				source_back_layer = nil
				patched = true
			elsif emuticon.source_back_layer != nil
					source_back_layer = emuticon.source_back_layer
			end
			if(success == true)
				if(source_front_layer != nil)
					# only update mongo if file was uploaded successfully
					filename = ""
					if(emuticon.source_front_layer != nil)
						filename = make_icon_name(emuticon.source_front_layer.rpartition('.').first, File.extname(source_front_layer[:filename]), true, true)
					else
						filename = make_icon_name(nameNewEmuticon(package.name, name, "-fg"), File.extname(source_front_layer[:filename]), false, true)
					end
					success = upload_file_to_s3(package.name,source_front_layer,filename, awsconnection)
					if(success == true)
						source_front_layer = filename
						patched = true
					end
				elsif emuticon.source_front_layer != nil && removesource_front_layer == "true"
					source_front_layer = nil
					patched = true
				elsif emuticon.source_front_layer != nil
					source_front_layer = emuticon.source_front_layer
				end
			end
			if(success == true)
				if(source_user_layer_mask != nil)
					# only update mongo if file was uploaded successfully
					filename = ""
					if(emuticon.source_user_layer_mask != nil)
						filename = make_icon_name(emuticon.source_user_layer_mask.rpartition('.').first, File.extname(source_user_layer_mask[:filename]), true, true)
					else
						filename = make_icon_name(nameNewEmuticon(package.name, name, "-mask"), File.extname(source_user_layer_mask[:filename]), false, true)
					end
					success = upload_file_to_s3(package.name,source_user_layer_mask, filename, awsconnection)
					if(success == true)
						source_user_layer_mask = filename
						patched = true
					end
				elsif emuticon.source_user_layer_mask != nil && removesource_user_layer_mask == "true"
					source_user_layer_mask = nil
					patched = true
				elsif emuticon.source_user_layer_mask != nil
					source_user_layer_mask = emuticon.source_user_layer_mask
				end
			end
			if(patched)
				patched_on = Time.now.utc.iso8601
			end

			if(use_for_preview != nil)
				if(use_for_preview == "true")
					use_for_preview = true
				elsif use_for_preview == "false"
					if emuticon.use_for_preview != nil
						use_for_preview = nil
					end
				end
			end
			if(success == true)
				
				id = emuticon.id
				package.emuticons.delete_if {|pemuticon| pemuticon.name == emuticon.name}
				package.save
				package = getPackageByName(package_name,mongoconnection)
				createNewEmuticon(package, id, name, source_back_layer, source_front_layer, source_user_layer_mask, duration, frames_count, thumbnail_frame_index, palette, patched_on, tags, use_for_preview)
				package.save


				package = getPackageByName(package_name,mongoconnection)
				if(patched && package.emuticons.length >= 6)
					package.cms_state = "zip"
					package.save
				end
			end
		end

		return success

	rescue StandardError => e

		return "updateEmuticon" + e.to_s

	ensure
		package = getPackageByName(package_name,mongoconnection)
		package.cms_proccessing = false
		package.save
	end
end