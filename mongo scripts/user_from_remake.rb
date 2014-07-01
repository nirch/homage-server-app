require 'mongo'
require 'date'
require 'time'

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")

remake_id_string = ARGV[0]
remake_id = BSON::ObjectId.from_string(remake_id_string)

remake = prod_remakes.find_one(remake_id)
user = prod_users.find_one(remake["user_id"])

#puts remake
puts user