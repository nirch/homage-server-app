gem 'mongo', '=1.9.2'
require 'mongo'
require 'date'
require 'time'

PROD_DB = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
PROD_USERS = PROD_DB.collection("Users")
PROD_REMAKES = PROD_DB.collection("Remakes")
PROD_STORIES = PROD_DB.collection("Stories")

TEST_DB = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
TEST_USERS = TEST_DB.collection("Users")
TEST_REMAKES = TEST_DB.collection("Remakes")
TEST_STORIES = TEST_DB.collection("Stories")
