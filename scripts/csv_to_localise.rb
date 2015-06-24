require 'net/http'
require 'open-uri'
require 'csv'

def get_translate_uri(asset_id, locale)
	key = '04e3fa5e23a879160d40d9e1517712e2'
	url = "https://localise.biz/api/translations/#{asset_id}/#{locale}?key=#{key}"
	return URI.parse(url)
end

csv_path = "/Users/nirchannes/Documents/Emu/Translations/emu-es.csv"#ARGV[0]
locale = "es"#ARGV[1]

default_uri = get_translate_uri(nil, nil)
http = Net::HTTP.new(default_uri.host, default_uri.port)
http.use_ssl = true

CSV.foreach(csv_path, encoding:"UTF-8") do |row|
	asset_id = row[0]
	translation = row[1]
	if translation && translation != nil then
		puts asset_id + "=" + translation
		uri = get_translate_uri asset_id, locale
		request = Net::HTTP::Post.new(uri.request_uri)
		request.body = translation
		response = http.request(request)
		puts "response: " + response.message
		puts
	end
end


# # Translate
# asset_id = 'TRY_AGAIN'
# locale = 'fr'
# translation = 'sublime!'

# uri = get_translate_uri asset_id, locale
# http = Net::HTTP.new(uri.host, uri.port)
# http.use_ssl = true

# request = Net::HTTP::Post.new(uri.request_uri)
# request.body = translation

# response = http.request(request)
# puts response


