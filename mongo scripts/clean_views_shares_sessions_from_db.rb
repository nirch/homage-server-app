require 'time'
require 'date'
require 'mongo'
require 'json'
require 'uri'
require 'open-uri'


DB = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db()
REMAKES = DB.collection("Remakes")
USERS = DB.collection("Users")
SHARES = DB.collection("Shares")
VIEWS =  DB.collection("Views")
SESSIONS = DB.collection("Sessions")

VIEWS.remove({})
SHARES.remove({})
SESSIONS.remove({})