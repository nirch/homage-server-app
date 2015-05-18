#encoding: utf-8

# Given a list of preffered languages (in format similar to what is passed in Accept-Language http headers)
# will add to the config the localization info of the most preffered language (if found in mongo).
# will fallback to en, if not found. If even 'en' not found will not add localization info.
def add_localization_info(config, connection, preffered_languages)
	if preffered_languages == nil
		return
	end
	
	preffered_languages = preffered_languages.split(",")
	most_preffered_language = preffered_languages[0]
	
	localization_info = localization_info_for_language(most_preffered_language, connection)
	if localization_info != nil
		config["localization"] = localization_info
	end
end


# searches mongo for a launguage and return info if founf
# will search:
#	1. The exact language by provided id
#	2. if not found, the less specific language related to the provided id (for example: es if nothing found for es-mx)
#   3. if still not found, fallbacks to en
def localization_info_for_language(lang, connection)
	# Search for the exact language
	info = connection.db().collection("translations").find({"_id"=>lang}).to_a	
	
	# If not found, search for the more general one.
	ls_lang = less_specific_language(lang)
	info = connection.db().collection("translations").find({"_id"=>ls_lang}).to_a if ls_lang != nil && info.count != 1	

    # If still not found, just get english as fallback
	info = connection.db().collection("translations").find({"_id"=>"en"}).to_a if info.count != 1

	# return the localisation info
	if info.count == 1
		return info
	end
	
	return nil
end


# If language is specific (en-us, es-mx etc) take the less specific part and return it.
# Otherwise will return nil
def less_specific_language(lang)
	ls_lang = lang.split('-')
	return ls_lang if ls_lang.count > 1
	return nil
end