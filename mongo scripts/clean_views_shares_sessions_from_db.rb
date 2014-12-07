require 'time'
require 'date'
require 'mongo'
require 'json'
require 'uri'
require 'open-uri'


DB = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db()
#Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db()
REMAKES = DB.collection("Remakes")
USERS = DB.collection("Users")
SHARES = DB.collection("Shares")
VIEWS =  DB.collection("Views")
SESSIONS = DB.collection("Sessions")
IMPRESSIONS = DB.collection("Impressions")
LIKES = DB.collection("Likes")

# VIEWS.remove({})
# SHARES.remove({})
# SESSIONS.remove({})
# IMPRESSIONS.remove({})
# LIKES.remove({})

# REMAKES.update({},{"$set" => {like_count:0 , share_count:0, web_impressions:0, 
# 								unique_significant_views:0, unique_views:0, unique_web_impressions:0, 
# 								significant_views:0, views:0}},{multi: true})


# remakes = REMAKES.find({"unique_significant_views" => {"$exists"=>false}})
# puts remakes.count
# for remake in remakes do
# 	puts remake["_id"].to_s
# end

result = REMAKES.update({"like_count" => {"$exists"=>false}}, {"$set" => {like_count:0}}, {multi:true})
puts result
result = REMAKES.update({"share_count" => {"$exists"=>false}}, {"$set" => {share_count:0}}, {multi:true})
puts result
result = REMAKES.update({"web_impressions" => {"$exists"=>false}}, {"$set" => {web_impressions:0}}, {multi:true})
puts result
result = REMAKES.update({"unique_views" => {"$exists"=>false}}, {"$set" => {unique_views:0}}, {multi:true})
puts result
result = REMAKES.update({"unique_web_impressions" => {"$exists"=>false}}, {"$set" => {unique_web_impressions:0}}, {multi:true})
puts result
result = REMAKES.update({"significant_views" => {"$exists"=>false}}, {"$set" => {significant_views:0}}, {multi:true})
puts result
result = REMAKES.update({"unique_significant_views" => {"$exists"=>false}}, {"$set" => {unique_significant_views:0}}, {multi:true})
puts result
result = REMAKES.update({"views" => {"$exists"=>false}}, {"$set" => {views:0}}, {multi:true})
puts result
