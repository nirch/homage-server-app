require File.expand_path '../mongo_helper.rb', __FILE__

NUM_OF_REMAKES_THRESHOLD = 5

launch_date = Time.parse("20140430")

counter = 0

# Getting all the top users
all_users = PROD_USERS.find(created_at:{"$gte"=>launch_date})
engaged_users = Hash.new
no_email_engaged_users = 0
for user in all_users do
	remakes_for_user = PROD_REMAKES.find(user_id:user["_id"], status:{"$in"=>[3,5]}, share_link:{"$exists"=>1}).count
	if remakes_for_user >= NUM_OF_REMAKES_THRESHOLD then
		if user["email"]
			engaged_users[user["_id"].to_s] = remakes_for_user
		else
			++no_email_engaged_users
		end
	end

	if counter >= 50 then
		break
	end
	counter += 1
end

puts engaged_users.count.to_s + " users, created " + NUM_OF_REMAKES_THRESHOLD.to_s + " or more (and have an email)"
puts no_email_engaged_users.to_s + " users, created " + NUM_OF_REMAKES_THRESHOLD.to_s + " or more but don't have an email..."

# Sorting by the most engaged user on top
sorted_users = engaged_users.sort_by {|k,v| v}.reverse

for sorted_user in sorted_users do
	puts sorted_user
end

# for user in engaged_users do
# 	puts user
# end