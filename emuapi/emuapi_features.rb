#encoding: utf-8

=begin

	Supported features by name
		implemented on iOS (v 1.9 and up)
		positional effect on the user layer (transforms - rotation, position, scale + tweening)
		gray scale effect on the user layer
		dynamic mask effect on the user layer

		planned on future versions:
			color tint effect on user layer 
			alpha channel effect on user layer
=end

# Given a client name and a client_version, returns a filter on packages
# so only packages supported by that client will be provided to that client
def supported_features_filter_for_client(client_name, client_version)
	# by default, will return only packages that have no "required version" set.
	version_string = formatted_version_string(client_version)
	if (client_name != "Emu iOS" and client_name !="Emu Android") or version_string == nil
		filter = {
			"required_ios_version"=>{"$exists"=>false}, 
			"required_android_version"=>{"$exists"=>false}
		}
		return filter
	end

	# Some packs use features available only starting from a given iOS or Android client
	
	# iOS
	if client_name == "Emu iOS"
		filter = {
			"$or"=>[
				{"required_ios_version"=>{"$exists"=>false}}, 		# packs with no minimal requirement
				{"required_ios_version"=>{"$lte"=>version_string}}	# packs with a minimal requirement for iOS
			]
		}
		return filter
	end

	# Android
	if client_name == "Emu Android"
		filter = {
			"$or"=>[
				{"required_android_version"=>{"$exists"=>false}},		# packs with no minimal requirement
				{"required_android_version"=>{"$lte"=>version_string}}	# packs with a minimal requirement for Android
			]
		}
		return filter
	end

end

def formatted_version_string(v)
	return v.split(".").map{|s|"%05d" %  s.to_i }.join("_") rescue nil
end
