require 'mongo'
require 'date'
require 'time'

#db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10005/emu-prod").db
db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10009/emu-dev-test").db
packages = db.collection("packages")

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