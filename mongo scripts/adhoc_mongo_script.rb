require 'mongo'

db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
users = db.collection("Users")

x = users.find({is_public:false})
puts x.count