require 'mongo'
require 'date'
require 'time'

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")

remake_id = BSON::ObjectId.from_string("53860c720be04462e6000007")

remake = prod_remakes.find_one(remake_id)
user = prod_users.find_one(remake["user_id"])

puts user