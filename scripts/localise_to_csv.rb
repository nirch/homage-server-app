require 'net/http'
require 'json'
require 'csv'

API_HTTP_PREFIX = "https://localise.biz/api"
KEY = '04e3fa5e23a879160d40d9e1517712e2'
EN_LOCALE = "en"

def get_assets_uri(prefix, key)
	url = "#{prefix}/assets/?key=#{key}"
	return URI.parse(url)
end

def get_translate_uri(prefix, asset_id, locale, key)
	url = "#{prefix}/translations/#{asset_id}/#{locale}?key=#{key}"
	return URI.parse(url)
end

csv_file = CSV.open("/Users/nirchannes/Documents/emu.csv", "wb")

assets_uri = get_assets_uri(API_HTTP_PREFIX, KEY)
assets_json = Net::HTTP.get(assets_uri)
assets_array = JSON.parse(assets_json)
for asset in assets_array do
	asset_id = asset["id"]
	asset_notes = asset["notes"]

	# Getting the english translation
	asset_en_translation_uri = get_translate_uri(API_HTTP_PREFIX, asset_id, EN_LOCALE, KEY)
	asset_en_translation_json = Net::HTTP.get(asset_en_translation_uri)
	asset_en_translation_array = JSON.parse(asset_en_translation_json)
	asset_en_translation = asset_en_translation_array["translation"]

	csv_file << [asset_id, asset_notes, asset_en_translation]
	#puts "#{asset_id}; #{asset_notes}; #{asset_en_translation}"	
end

csv_file.close