require 'net/http'
require 'json'

def get_translations_uri(locale)
	format = 'json'
	key = '04e3fa5e23a879160d40d9e1517712e2'
	tags = 'server'
	url = "https://localise.biz/api/export/locale/#{locale}.#{format}?key=#{key}&filter=#{tags}"
	return URI.parse(url)
end

locale = 'en'#ARGV[0]
uri = get_translations_uri(locale)
translation_json = Net::HTTP.get(uri)
translation_hash = JSON.parse(translation_json)
puts translation_hash

