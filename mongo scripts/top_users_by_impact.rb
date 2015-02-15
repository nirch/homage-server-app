require 'mongo'
require 'date'
require 'time'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
db = prod_db

NUM_OF_REMAKES_THRESHOLD = ARGV[0].to_i

module ShareMethod
	CopyUrlShareMethod = 0
	FacebookShareMethod = 1
	WhatsappShareMethod = 2
	EmailShareMethod = 3 
	MessageShareMethod = 4
	WeiboShareMethod = 5
	TwitterShareMethod = 6
	GooglePlusShareMethod = 7
	PinterestShareMethod = 8
end

shares_collection = db.collection("Shares")
views_collection = db.collection("Views")
remakes_collection = db.collection("Remakes")
users_collection = db.collection("Users")

grouped_views_by_share = views_collection.aggregate(
	[
		{ "$group" => {"_id" => {"origin_id" => "$origin_id"}, "views" => {"$sum" => 1} } },
		{ "$sort" => {"views" => -1} }
	]
)

grouped_views_by_share[1..NUM_OF_REMAKES_THRESHOLD + 1].each do |view_by_share|
	# Since there is a big that origin_id is sometimes BSON::ObjectId and sometimes String - making sure it is ObjectId
	share_id = view_by_share["_id"]["origin_id"].is_a?(BSON::ObjectId) ? view_by_share["_id"]["origin_id"] : BSON::ObjectId.from_string(view_by_share["_id"]["origin_id"])

	share = shares_collection.find_one(share_id)
	remake = remakes_collection.find_one(share["remake_id"])
	user = users_collection.find_one(remake["user_id"])

	puts "Share Id: " + share_id.to_s
	puts "Remake Id: " + remake["_id"].to_s
	puts "Views: " + view_by_share["views"].to_s

	uniqe_views_set = Set.new
	views = views_collection.find({origin_id: view_by_share["_id"]["origin_id"]})
	for view in views do
		uniqe_views_set.add(view["cookie_id"].to_s) if view["cookie_id"]
		uniqe_views_set.add(view["user_id"].to_s) if view["user_id"]		
	end
	puts "Unique views: " + uniqe_views_set.count.to_s

	case share["share_method"]
	when ShareMethod::CopyUrlShareMethod
		puts "Shared via Clipboard"
	when ShareMethod::FacebookShareMethod
		puts "Shared via Facebook"
	when ShareMethod::WhatsappShareMethod
		puts "Shared via Whatsapp"
	when ShareMethod::EmailShareMethod
		puts "Shared via Email"
	when ShareMethod::MessageShareMethod
		puts "Shared via SMS"
	when ShareMethod::WeiboShareMethod
		puts "Shared via Weibo"
	when ShareMethod::TwitterShareMethod
		puts "Shared via Twitter"
	when ShareMethod::GooglePlusShareMethod
		puts "Shared via Google Plus"
	when ShareMethod::PinterestShareMethod
		puts "Shared via Pinterest"
	else
		puts "Shared via " + share["share_method"].to_s
	end

	puts "User Id: " + user["_id"].to_s
	if user["email"]
		if user["facebook"]
			puts "User Name: " + user["facebook"]["name"]
		end
		puts "User email: " + user["email"]
	else
		puts "User is guest"
	end

	puts  
end


# for view_by_share in grouped_views_by_share do
# 	puts view_by_share["_id"].to_s + ": " + view_by_share["views"].to_s
# end


# shares_with_views = Array.new
# all_shares = shares_collection.find()
# for share in all_shares do
# 	share_id = share["_id"]
# 	views_from_share = views_collection.find({origin_id: share_id})
# 	if views_from_share.count > 0
# 		puts views_from_share.count
# 		shares_with_views.push share_id
# 	end
# end

# puts shares_with_views