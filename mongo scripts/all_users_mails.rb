require 'mongo'
require 'date'
require 'time'

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")

date_input = "20140430"
from_date = Time.parse(date_input)

users = prod_users.find(created_at:{"$gte"=>from_date})
for user in users do
	if user["email"] then
		puts user["email"]
	end 

end

