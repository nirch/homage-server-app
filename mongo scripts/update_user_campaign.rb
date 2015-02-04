require 'mongo'
require 'date'
require 'time'
require 'aws-sdk'
require 'open-uri'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
db = prod_db

users_collection = db.collection("Users")

homage_campaign_id = db.collection("Campaigns").find_one({name: /^homageapp$/i})["_id"]
puts homage_campaign_id

# Getting all the users without campaign
users_without_campaign = users_collection.find(campaign_id:{"$exists"=>false})
puts users_without_campaign.count

# # Updating all of these users with Homage campaign id
# result = users_collection.update({campaign_id:{"$exists"=>false}}, {"$set" => {campaign_id: homage_campaign_id}}, {multi:true})
# puts result

# users_without_campaign = users_collection.find(campaign_id:{"$exists"=>false})
# puts users_without_campaign.count