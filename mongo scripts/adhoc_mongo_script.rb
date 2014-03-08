require 'mongo'

db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
users = db.collection("Users")
remakes = db.collection("Remakes")

public_users_cursor = users.find({is_public:true})
public_users = Array.new

for user in public_users_cursor do
	public_users.push(user["_id"])
end

all_remakes = remakes.find({story_id: BSON::ObjectId.from_string("52de83db8bc427751c000305"), status:3})
puts "All remakes = " + all_remakes.count.to_s

yoav_remakes = remakes.find({story_id: BSON::ObjectId.from_string("52de83db8bc427751c000305"), status:3, user_id:"yoav@homage.it"})
puts "Yoav remakes = " + yoav_remakes.count.to_s

public_remakes = remakes.find({story_id: BSON::ObjectId.from_string("52de83db8bc427751c000305"), status:3, user_id:{"$in" => public_users}})
puts "Public remakes = " + public_remakes.count.to_s



#story_id = BSON::ObjectId.from_string("52de83db8bc427751c000305")
