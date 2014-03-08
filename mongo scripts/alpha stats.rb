require 'mongo'

log_file = File.new("alpha_stats.log", "a+")
log_file.sync = true
$stdout.reopen(log_file)
$stderr.reopen(log_file)

fake_users = Set.new ["yoav@homage.it", "nir@homage.it", "test@homage.it", "tomer@homage.it", "ran@homage.it","Hila.ronen1@gmail.com", "Ranpeer@gmail.com", "qa@yoav.com", "tomer.harry@gmail.com", "Tomer@homage.it", "to@homage.iy", "Nir@homage.it", "qaqa@yoav.com", "qaqaqa@yoav.com", "yoav@demoday.com", "eharry@013.net", "hiorit@gmail.com", "grgthy@grgt.nyny", "yoav@qa.com", "yoav@yoav.com", "yoav@big.nb", "yov@bbb.nnn", "yo@bb.nn", "yo@dsf.com", "mixpanelTest@yoav.com", "post.pc.developer@gmail.com", "paka@gmail.com", "juju@unusual.jn"]

user_testing_users = Set.new ["shaharburg@gmail.com", "ran.turgeman@gmail.com", "Erez.robinson@gmail.com", "yalinir11@gmail.com", "darbel4399@gmail.com", "yaelrre@gmail.com"]

biased_users = Set.new ["zivchannes@gmail.com"]

db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
users_collection = db.collection("Users")
remakes_collection = db.collection("Remakes")
users = users_collection.find({})

total_users = Set.new
for user in users do
	user_id = user["_id"]
	total_users.add(user_id)
end

puts 'Total Users = ' + total_users.count.to_s
real_users = total_users.subtract(fake_users).subtract(user_testing_users)
puts 'Real Users = ' + real_users.count.to_s

num_of_users_completed = 0
#all_completed_remake_ids = ""
all_completed_remake_ids = Array.new

for user in real_users do
	puts
	puts "*** " + user + " ***"

	remakes_created = remakes_collection.find({user_id: user, status: {"$ne"=>0}})
	puts "num of remakes created (not status 0) = " + remakes_created.count.to_s

	remakes_completed = remakes_collection.find({user_id: user, status: 3})
	puts "num of remakes completed = " + remakes_completed.count.to_s
	if remakes_completed.count > 0 then
		remakes_completed_ids = Array.new
		for completed_remake in remakes_completed do
			remakes_completed_ids.push(completed_remake["_id"].to_s)
			#remakes_completed_string += completed_remake["_id"].to_s + ";"
			#puts completed_remake[""]
		end
		puts "remakes completed ID = " + remakes_completed_ids.to_s
		all_completed_remake_ids += remakes_completed_ids
		num_of_users_completed += 1
	end
end

puts
puts "Number of completed remakes = " + all_completed_remake_ids.count.to_s
puts "All completed remake IDs = " + all_completed_remake_ids.to_s
puts

prenetage = num_of_users_completed / real_users.count.to_f * 100
puts "% of users that were able to finish creating at least 1 video = " + prenetage.to_i.to_s + "%"
