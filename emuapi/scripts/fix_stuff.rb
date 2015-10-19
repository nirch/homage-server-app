require 'mongo'
require 'date'
require 'time'

#$db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10005/emu-prod").db
#$db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10073/emu-test").db

#$db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10009/emu-dev-test").db
#$db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10008/emu-dev-prod").db

def fix_timestamps()
	packages = $db.collection("packages")
	for pack in packages.find()
		d1 = pack["meta_data_last_update"]
		if d1 != nil
			d1 = Integer(d1)
		else 
			d1 = 0
		end

		d2 = pack["last_update"]
		if d2 != nil
			d2 = Integer(d2)
		else 
			d2 = 0
		end

		t = [d1,d2].max

		if t < 1000
			puts "failed"
			abort
		end
		db.collection("packages").update(
			{"_id"=>pack["_id"]},
			{"$set"=>{
				"data_update_time_stamp"=>t
				}
			}
		)
	end
end

def fix_country_codes()
	packages = $db.collection("packages")
	# All packs must have the country code field
	for pack in packages.find()
		cc = pack["country_code"]
		if cc == nil then cc = ["any"] end
		if not cc.kind_of?(Array)
			cc = cc.strip().split(",").map(&:strip)
		end
		$db.collection("packages").update(
			{"_id"=>pack["_id"]},
			{"$set"=>{"country_code"=>cc}}
		)

		bcc = pack["blocked_country_code"]
		if bcc == nil then bcc = [] end
		if not bcc.kind_of?(Array)
			bcc = bcc.strip().split(",").map(&:strip)
		end
		$db.collection("packages").update(
			{"_id"=>pack["_id"]},
			{"$set"=>{"blocked_country_code"=>bcc}}
		)
		puts pack["name"]
	end
end

fix_country_codes()
