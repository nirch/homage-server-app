require 'net/http'
require 'json'
require 'mongo'

$key = "e3d35e756dbdd6bacbd717690096974b"

def existing_packs_uri(locale)
	format = 'json'
	tags = 'Server'
	url = "https://localise.biz/api/export/locale/#{locale}.#{format}?key=#{$key}&filter=#{tags}"
	return URI.parse(url)
end

def loc_id_from_name(pack_name)
	loc_id = pack_name.upcase
	return "PACKAGE_%s" % loc_id
end

def add_new_loc_asset(loc_id, label)
	# Add
	url = "https://localise.biz/api/assets?key=#{$key}"
	uri = URI.parse(url)
	res = Net::HTTP.post_form(uri, 'name' => loc_id.sub("_", " "), 'id' => loc_id)

	# Tag
	url = "https://localise.biz/api/assets/#{loc_id}/tags?key=#{$key}"
	uri = URI.parse(url)
	res = Net::HTTP.post_form(uri, 'name' => "Server")

	# Default translation
	http = Net::HTTP.new("localise.biz", 443)
	http.use_ssl = true
	url = "https://localise.biz/api/translations/#{loc_id}/en?key=#{$key}"
	uri = URI.parse(url)
	request = Net::HTTP::Post.new(uri.request_uri)
	request.body = label
	response = http.request(request)
end

# Get existing localized packs
uri = existing_packs_uri("en")
json = Net::HTTP.get(uri)
existing = JSON.parse(json)

# Get existing packs in mongo
db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10073/emu-test").db()
packs = db.collection("packages").find()
for pack in packs
	pack_name = pack["name"]
	loc_id = loc_id_from_name(pack_name)
	if existing[loc_id] == nil
		# Found missing pack in localization
		puts loc_id
		add_new_loc_asset(loc_id, pack["label"])
	end
end
