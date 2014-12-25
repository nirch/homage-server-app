require File.expand_path '../mongo_helper.rb', __FILE__

env = ARGV[0]
share_id = BSON::ObjectId.from_string(ARGV[1])

if env == 'p' then
	db = PROD_DB
elsif env == 't' then
	db = TEST_DB
end
		
shares = db.collection("Shares")
share = shares.find_one(share_id)
puts share["remake_id"]
