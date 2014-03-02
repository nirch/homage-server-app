require 'mongo'

db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
remakes = db.collection("Remakes")
users = db.collection("Users")

# users_to_delete = Set.new ["yoav@homage.it", "nir@homage.it", "test@homage.it", "tomer@homage.it", "ran@homage.it","Hila.ronen1@gmail.com", "Ranpeer@gmail.com", "qa@yoav.com", "tomer.harry@gmail.com", "Tomer@homage.it", "to@homage.iy", "Nir@homage.it", "qaqa@yoav.com", "qaqaqa@yoav.com", "yoav@demoday.com", "eharry@013.net", "hiorit@gmail.com", "grgthy@grgt.nyny", "yoav@qa.com", "yoav@yoav.com", "yoav@big.nb", "yov@bbb.nnn", "yo@bb.nn", "yo@dsf.com", "mixpanelTest@yoav.com", "post.pc.developer@gmail.com", "paka@gmail.com", "juju@unusual.jn"]

# for user_to_delete in users_to_delete do
# 	puts "Deleting user: " + user_to_delete.to_s
	
# 	remakes_to_delete = remakes.find({user_id: user_to_delete})
# 	puts "Deleting " + remakes_to_delete.count.to_s + " remakes"
# 	for remake_to_delete in remakes_to_delete do
# 		remakes.remove({_id: remake_to_delete["_id"]})		
# 	end
	
# 	users.remove({_id: user_to_delete})
# end