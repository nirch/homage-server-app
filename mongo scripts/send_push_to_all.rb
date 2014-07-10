require 'mongo'
require 'date'
require 'time'
require 'houston'

# Production mongo
prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")

# Prodcution APN
APN = Houston::Client.production
APN.certificate = File.read("../certificates/homage_push_notification_prod.pem")
APN.passphrase = "homage"

# Notification Content
alert = "Take Part in the World Cup! Vamos!"
sound = "default"
custom_data = {type: 2, story_id: "53b17db89a452198f80004a6"}

# Getting all the users
date_input = "20140430"
from_date = Time.parse(date_input)
users = prod_users.find(created_at:{"$gte"=>from_date})

# Getting all the push tokens
push_tokens = Set.new
for user in users do
	if user["devices"] then
		for device in user["devices"] do
			if device["push_token"] then
				push_tokens.add(device["push_token"])
				#break
			end
		end
	end
end

# Pushing to all tokens
for token in push_tokens do
	notification = Houston::Notification.new(device: token)
	notification.alert = alert
	notification.sound = sound
	notification.custom_data = custom_data
	APN.push(notification)
end

puts "Pushed to " + push_tokens.count.to_s + " devices"

