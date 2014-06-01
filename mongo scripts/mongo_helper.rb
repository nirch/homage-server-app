require 'mongo'
require 'date'
require 'time'

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
PROD_USERS = prod_db.collection("Users")
PROD_REMAKES = prod_db.collection("Remakes")
PROD_STORIES = prod_db.collection("Stories")

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
TEST_USERS = test_db.collection("Users")
TEST_REMAKES = test_db.collection("Remakes")
TEST_STORIES = test_db.collection("Stories")
