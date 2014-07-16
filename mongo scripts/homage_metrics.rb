require 'mongo'
require 'date'
require 'time'

prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
prod_users = prod_db.collection("Users")
prod_remakes = prod_db.collection("Remakes")

launch_date = Time.parse("20140430Z")

def map_remakes_to_users(remakes)
	users = Hash.new
	for remake in remakes do
		if !users[remake["user_id"]] then
			users[remake["user_id"]] = 1
		else
			users[remake["user_id"]] = users[remake["user_id"]] + 1
		end
	end
	return users
end

def num_more_than_one(users)
	num_of_users = 0
	for num_of_remakes in users.values do
		if num_of_remakes > 1 then
			num_of_users += 1
		end
	end
	return num_of_users
end

# Number of users
total_users = prod_users.find(created_at:{"$gte"=>launch_date})
total_users_num = total_users.count
puts "Number of users: " + total_users_num.to_s

# Number of remakes
done_remakes = prod_remakes.find(created_at:{"$gte"=>launch_date}, status:3)
puts "Number of remakes (status 3): " + done_remakes.count.to_s

# Number of remakes that are deleted but were once done
deleted_remakes = prod_remakes.find(created_at:{"$gte"=>launch_date}, status:5)
was_done_remakes = Array.new
for deleted_remake in deleted_remakes do
	last_footage = deleted_remake["footages"][deleted_remake["footages"].count - 1]
	if deleted_remake["share_link"] then
		was_done_remakes.push(deleted_remake)
	end
end
puts "Number of remakes that are deleted but were once done: " + was_done_remakes.count.to_s

# Number of "disapointed" remakes, remakes that were clicked on create movie but were not done
total_remakes = prod_remakes.find(created_at:{"$gte"=>launch_date})
puts "Total number of remakes: " + total_remakes.count.to_s
disapointed_remakes = Array.new
for remake in total_remakes do
	#if remake["status"] != 3 && remake["render_start"] && !remake["render_end"] && !remake["share_link"] then
	if remake["render_start"] && !remake["render_end"] then
		disapointed_remakes.push(remake)
	end
end
puts "Number of disapointed remakes: " + disapointed_remakes.count.to_s

start_render_remakes = prod_remakes.find(created_at:{"$gte"=>launch_date}, render_start:{"$exists"=>1})
puts "Number of remakes start render: " + start_render_remakes.count.to_s

puts "=========================================="

# User metrics
puts total_users_num.to_s + " total logged in users"
facebook_users = 0
email_users = 0
guest_users = 0
push_tokens = 0
for user in total_users do
	if user["facebook"] then
		facebook_users += 1
	elsif user["email"] then
		email_users += 1
	else
		guest_users +=1
	end

	if user["devices"] then
		for device in user["devices"] do
			if device["push_token"] then
				push_tokens += 1
				break
			end
		end
	end
end
facebook_percentage = facebook_users.to_f / total_users_num.to_f * 100
email_percentage = email_users.to_f / total_users_num.to_f * 100
guest_percentage = guest_users.to_f / total_users_num.to_f * 100
push_percentage = push_tokens.to_f / total_users_num.to_f * 100
puts facebook_percentage.round.to_s + "% facebook (" + facebook_users.to_s + " users)"
puts email_percentage.round.to_s + "% email (" + email_users.to_s + " users)"
puts guest_percentage.round.to_s + "% guest (" + guest_users.to_s + " users)"
puts push_percentage.round.to_s + "% of the users with push token (" + push_tokens.to_s + " users)"


# Users clicked 'Create Movie'
start_render_users = map_remakes_to_users(start_render_remakes)
start_render_percentage = start_render_users.count.to_f / total_users_num.to_f * 100
puts start_render_percentage.round.to_s + "% of the users clicked 'Create Movie' (" + start_render_users.count.to_s + " users, " + start_render_remakes.count.to_s + " remakes)" 
start_render_more_than_one_num = num_more_than_one(start_render_users)
start_render_more_than_one_percentage  = start_render_more_than_one_num.to_f / total_users_num.to_f * 100
puts start_render_more_than_one_percentage.round.to_s + "% of the users clicked 'Create Movie' more than once (" + start_render_more_than_one_num.to_s + " users)" 

# Users have/had a done video
have_had_done_remakes = done_remakes.to_a + was_done_remakes
have_had_done_users = map_remakes_to_users(have_had_done_remakes)
have_had_done_percentage = have_had_done_users.count.to_f / total_users_num.to_f * 100
puts have_had_done_percentage.round.to_s + "% of the users have or had a ready movie (" + have_had_done_users.count.to_s + " users, " + have_had_done_remakes.count.to_s + " remakes)" 
have_had_done_more_than_one_num = num_more_than_one(have_had_done_users)
have_had_done_more_than_one_percentage  = have_had_done_more_than_one_num.to_f / total_users_num.to_f * 100
puts start_render_more_than_one_percentage.round.to_s + "% of the users have or had more than one ready movie (" + have_had_done_more_than_one_num.to_s + " users)" 

# Users have a video
done_remakes.rewind!
done_users = map_remakes_to_users(done_remakes)
done_percentage = done_users.count.to_f / total_users_num.to_f * 100
puts done_percentage.round.to_s + "% of the users have a ready movie (" + done_users.count.to_s + " users, " + done_remakes.count.to_s + " remakes)" 
done_more_than_one_num = num_more_than_one(done_users)
done_more_than_one_percentage  = done_more_than_one_num.to_f / total_users_num.to_f * 100
puts done_more_than_one_percentage.round.to_s + "% of the users have more than one ready movie (" + done_more_than_one_num.to_s + " users)" 

# Users deleted a done video
remakes_deleted_percentage = was_done_remakes.count.to_f / have_had_done_remakes.count.to_f * 100
puts remakes_deleted_percentage.round.to_s + "% of the completed remakes were deleted (" + was_done_remakes.count.to_s + " remakes)"

# Disapointed users
disapointed_users = map_remakes_to_users(disapointed_remakes)
disapointed_percentage = disapointed_users.count.to_f / total_users_num.to_f * 100
puts disapointed_percentage.round.to_s + "% of the users have at least 1 failed remake (" + disapointed_users.count.to_s + " users, " + disapointed_remakes.count.to_s + " remakes)" 

