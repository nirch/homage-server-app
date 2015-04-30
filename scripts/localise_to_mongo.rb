require 'net/http'
require 'json'
require 'mongo'

def get_translations_uri(locale)
	format = 'json'
	key = '04e3fa5e23a879160d40d9e1517712e2'
	tags = 'server'
	url = "https://localise.biz/api/export/locale/#{locale}.#{format}?key=#{key}&filter=#{tags}"
	return URI.parse(url)
end

locale = 'fr'#ARGV[0]
uri = get_translations_uri(locale)
translation_json = Net::HTTP.get(uri)
translation_hash = JSON.parse(translation_json)
translation_hash["_id"] = locale
puts translation_hash

db_scratchpad = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10073/emu-test").db()
translations = db_scratchpad.collection("translations")
x = translations.update({_id: locale}, translation_hash, {upsert:true})
puts x




