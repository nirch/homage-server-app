require 'mongo'

db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
stories = db.collection("Stories")

# result = stories.remove({_id: BSON::ObjectId.from_string("53130be90fc1f1cc2200012e")})
# puts result