#encoding: utf-8
require 'sinatra'
require 'mongo'
require 'uri'
require 'json'
require 'open-uri'
require 'logger'
require 'net/http'
require 'sinatra/security'
require 'houston'
require 'time'

configure do
	# Global configuration (regardless of the environment)

end

configure :production do
	# Production DB connection
	db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod")
	set :db, db_connection.db()

	# Push notification certificate
	APN = Houston::Client.production
	APN.certificate = File.read(File.expand_path("../certificates/homage_push_notification_prod.pem", __FILE__))
	APN.passphrase = "homage"

	# Production AE server connection
	set :homage_server_foreground_uri, URI.parse("http://homage-render-prod-elb-882305239.us-east-1.elb.amazonaws.com:4567/footage")
	set :homage_server_render_uri, URI.parse("http://homage-render-prod-elb-882305239.us-east-1.elb.amazonaws.com:4567/render")

	set :logging, Logger::INFO
end

configure :test do
	# Test DB connection
	db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage")
	set :db, db_connection.db()

	# Push notification certificate
	# APN = Houston::Client.development
	# APN.certificate = File.read(File.expand_path("../certificates/homage_push_notification_dev.pem", __FILE__))
	APN = Houston::Client.production
	APN.certificate = File.read(File.expand_path("../certificates/homage_push_notification_prod.pem", __FILE__))
	APN.passphrase = "homage"


	# Test AE server connection
	set :homage_server_foreground_uri, URI.parse("http://54.83.32.172:4567/footage")
	set :homage_server_render_uri, URI.parse("http://54.83.32.172:4567/render")

	set :logging, Logger::DEBUG
end

before do
  logger.info "params=" + params.to_s
end

module RemakeStatus
  New = 0
  InProgress = 1
  Rendering = 2
  Done = 3
  Timeout = 4
  Deleted = 5
end

module FootageStatus
  Open = 0
  Uploaded = 1
  Processing = 2
  Ready = 3
end

module ErrorCodes
	InvalidPassword = 1001
	InvalidUserID = 1002
	FacebookToGuestForbidden = 1003
	FacebookToEmailForbidden = 1004
	EmailToGuestForbidden = 1005
end

module UserType
	GuestUser = 0
	FacebookUser = 1
	EmailUser = 2
end

module PushNotifications
	MovieReady = 0
	MovieTimout = 1
end

module ShareMethod
	CopyUrlShareMethod = 0
	FacebookShareMethod = 1
	WhatsappShareMethod = 2
	EmailShareMethod = 3 
end

# Get all stories
get '/stories' do
	stories_collection = settings.db.collection("Stories")
	stories_docs = stories_collection.find({}, {fields: {after_effects: 0}}).sort({order_id: 1})

	stories_json_array = Array.new
	for story_doc in stories_docs do
		stories_json_array.push(story_doc.to_json)
	end

	logger.info "Returning " + stories_json_array.count.to_s + " stories"

	stories = "[" + stories_json_array.join(",") + "]"
	# stories = JSON[stories_docs]
end

# Returns a given story id
get '/story/:story_id' do
	# input
	story_id = BSON::ObjectId.from_string(params[:story_id])

	logger.info "Getting story with id " + story_id.to_s

	# Fetching the story
	stories = settings.db.collection("Stories")
	story = stories.find_one(story_id)

	if story then
		story.to_json
	else
		status 404
	end
end


get '/test/user' do
	form = '<form action="/user" method="post" enctype="multipart/form-data"> e-mail: <input type="text" name="user_id"> <input type="submit" value="Create User"> </form>'
	erb form
end

# This methods recieves a source user and adds his device to the destination user (if the devices)
def add_devices(users, source_user, destination_user, destination_id)
	destination_devices = Set.new
	for device in destination_user["devices"]
		destination_devices.add(device["identifier_for_vendor"])
	end

	for device in source_user["devices"]
		if !destination_devices.include?(device["identifier_for_vendor"]) then
			#logger.info "Adding to user " + destination_id.to_s + " device " + device.to_s 
			users.update({_id: destination_id}, {"$push" => {devices: device} })
		end
	end
end


def handle_facebook_login(user)
	facebook_id = user["facebook"]["id"]

	users = settings.db.collection("Users")
	user_exists = users.find_one({"facebook.id" => facebook_id})

	if user_exists then
		logger.info "Facebook user <" + user["facebook"]["name"] + "> exists with id <" + user_exists["_id"].to_s + ">. returning existing user"
		add_devices(users, user, user_exists, user_exists["_id"])
		return user_exists["_id"], nil, false
	else
		# checking if the user exists with an email
		if user["email"] then
			email_exists = users.find_one({"email" => user["email"]})
			if email_exists then
				# This is an existing user which previously had an email login and now has a facebook login
				update_user_id = email_exists["_id"]
				logger.info "updating Email to Facebook for user " + update_user_id.to_s
				users.update({_id: update_user_id}, {"$set" => {facebook: user["facebook"]}})
				return update_user_id, nil, false
			end
		end

		new_user_id = users.save(user)	
		logger.info "New facebook user <" + user["facebook"]["name"] + "> saved in the DB with user_id <" + new_user_id.to_s + ">"
		return new_user_id, nil, true
	end
end

def handle_guest_login(user)
	users = settings.db.collection("Users")
	new_user_id = users.save(user)
	logger.info "New guest user saved in the DB with user_id <" + new_user_id.to_s + ">"
	return new_user_id, nil, true
end

def handle_password_login(user)
	email = user["email"]

	# Checking if this is a signup or login attempt
	users = settings.db.collection("Users")
	user_exists = users.find_one({"email" => email})
	if user_exists then

		if user_type(user_exists) == UserType::FacebookUser then
			logger.warn "An existing facebook user cannot login with email, connect with facebook"
			error_hash = { :message => "An existing facebook user cannot login with email, connect with facebook", :error_code => ErrorCodes::FacebookToEmailForbidden }
			return nil, [403, [error_hash.to_json]], nil	
		end

		logger.info "Attempt to login with email <" + email + ">"

		authenticated = Sinatra::Security::Password::Hashing.check(user["password"], user_exists["password_hash"])
		if authenticated then
			logger.info "User <" + email + "> successfully authenticated"
			add_devices(users, user, user_exists, user_exists["_id"])
			return user_exists["_id"], nil, false
		else
			logger.info "Authentication failed for user <" + email + ">"
			error_hash = { :message => 'Authentication failed, invalid password', :error_code => ErrorCodes::InvalidPassword }
			return nil, [401, [error_hash.to_json]], nil
		end
	else
		# Encrypt password (hash + salt)
		password_hash = Sinatra::Security::Password::Hashing.encrypt(user["password"])
		user["password_hash"] = password_hash
		user.delete("password")
		new_user_id = users.save(user)
		logger.info "New email user <" + user["email"] + "> saved in the DB with user_id <" + new_user_id.to_s + ">"
		return new_user_id, nil, true
	end
end

def handle_user_params(user)
	# Converting is_public to boolean (default is false)
	if user["is_public"] then
		user["is_public"] = to_boolean(user["is_public"])
	end

	# downcasing the emails (to avoid issues of uppercase/lowercase emails)
	if user["email"] then
		user["email"].downcase!
	end

	if user["device"] then
		devices = Array.new
		devices.push(user["device"])
		user["devices"] = devices
		user.delete("device")
	end
end

post '/user' do
	# input
	new_user = params

	logger.info "POST /user with params <" + params.to_s + ">"

	handle_user_params(new_user)
	new_user["created_at"] = Time.now

	new_user_type = user_type(new_user)

	# Handeling the differnet logins: facebook; email; guest
	if new_user_type == UserType::FacebookUser then
		user_id, error, first_use = handle_facebook_login new_user
	elsif new_user_type == UserType::EmailUser then
		user_id, error, first_use = handle_password_login new_user
	else
		user_id, error, first_use = handle_guest_login new_user
	end

	# Returning either the user or an error
	if user_id then
		users = settings.db.collection("Users")
		user = users.find_one(user_id)
		user[:first_use] = first_use
		response = user.to_json
	else
		response = error
	end 
end

def user_type(user)
	if user["facebook"] then
		return UserType::FacebookUser
	elsif user["email"] then
		return UserType::EmailUser
	else
		return UserType::GuestUser
	end
end

# Merging user a into user b and deleting user a
def merge_users(user_a, user_b)
	users = settings.db.collection("Users")
	remakes = settings.db.collection("Remakes")

	# Moving user_a remakes to user_b
	user_a_remakes = remakes.find({user_id: user_a["_id"]})
	for remake in user_a_remakes do
		logger.info "Moving remake " + remake["_id"].to_s + " from user " + user_a["_id"].to_s + " to user " + user_b["_id"].to_s
		remakes.update({_id: remake["_id"]}, {"$set" => {user_id: user_b["_id"]}})
	end

	add_devices(users, user_a, user_b, user_b["_id"])

	# removing this user
	logger.info "Deleting user " + user_a["_id"].to_s
	users.remove({_id: user_a["_id"]})
end

put '/user' do
	logger.info "params for put /user/v2: " + params.to_s

	update_user_id = BSON::ObjectId.from_string(params[:user_id])

	users = settings.db.collection("Users")
	existing_user = users.find_one(update_user_id)

	if !existing_user then
		# returning an error
		logger.warn "Trying to update a user that doesn't exist with id " + update_user_id.to_s
		error_hash = { :message => "User with id " + update_user_id.to_s + " doesn't exist", :error_code => ErrorCodes::InvalidUserID }
		return [404, [error_hash.to_json]]
	end

	handle_user_params(params)

	update_user_type = user_type(params)
	existing_user_type = user_type(existing_user)

	if update_user_type == UserType::GuestUser or existing_user_type == update_user_type then
		# if it is the same type of user, or the updates user looks like guest, then this is a simple update of user data
		logger.info "updating data for user " + update_user_id.to_s
		users.update({_id: update_user_id}, {"$set" => {is_public: params[:is_public]}})
	elsif existing_user_type == UserType::GuestUser and update_user_type == UserType::FacebookUser
		# Guest to Facebook user

		# Checking if there is another facebook user with the same ID
		facebook_user_exists = users.find_one({"facebook.id" => params[:facebook][:id]})
		if facebook_user_exists then
			logger.info "facebook id already exists, merging guest user " + update_user_id.to_s + " into facebook user " + facebook_user_exists["_id"].to_s
			merge_users(existing_user, facebook_user_exists)
			update_user_id = facebook_user_exists["_id"]
		else
			logger.info "updating Guest to Facebook for user " + update_user_id.to_s
			users.update({_id: update_user_id}, {"$set" => {facebook: params[:facebook], email: params[:email], is_public: params[:is_public]}})
		end
	elsif existing_user_type == UserType::GuestUser and update_user_type == UserType::EmailUser
		# Guest to Email user

		# Checking if there is another user with the same email
		email_user_exists = users.find_one({email: params[:email]})
		if email_user_exists then
			if user_type(email_user_exists) == UserType::FacebookUser then
				logger.warn "cannot downgrade a facebook user to an email user"
				error_hash = { :message => "cannot downgrade a facebook user to an email user", :error_code => ErrorCodes::FacebookToEmailForbidden }
				return [403, [error_hash.to_json]]				
			else
				logger.info "User with email " + params[:email] + " already exists, attempt to authenticate"
				# Attempting to authenticate the user
				authenticated = Sinatra::Security::Password::Hashing.check(params["password"], email_user_exists["password_hash"])
				if authenticated then
					logger.info "authentication succeeded, merging guest user " + update_user_id.to_s + " into email user " + email_user_exists["_id"].to_s
					merge_users(existing_user, email_user_exists)
					update_user_id = email_user_exists["_id"]
				else
					logger.info "Authentication failed for user <" + params[:email] + ">"
					error_hash = { :message => 'Authentication failed, invalid password', :error_code => ErrorCodes::InvalidPassword }
					return [401, [error_hash.to_json]]
				end
			end
		else
			logger.info "updating Guest to Email for user " + update_user_id.to_s
			password_hash = Sinatra::Security::Password::Hashing.encrypt(params["password"])
			users.update({_id: update_user_id}, {"$set" => {email: params[:email], password_hash: password_hash, is_public: params[:is_public]}})
		end
	elsif existing_user_type == UserType::FacebookUser and update_user_type == UserType::EmailUser
		# Error - Facebook to Email user
		logger.warn "cannot downgrade a facebook user to an email user"
		error_hash = { :message => "cannot downgrade a facebook user to an email user", :error_code => ErrorCodes::FacebookToEmailForbidden }
		return [403, [error_hash.to_json]]
	elsif existing_user_type == UserType::EmailUser and update_user_type == UserType::FacebookUser
		# Email to Facebook user
		logger.warn "updating email user to facebook user should be done with POST not PUT"
		error_hash = { :message => "updating email user to facebook user should be done with POST not PUT", :error_code => ErrorCodes::FacebookToEmailForbidden }
		return [403, [error_hash.to_json]]
	end

	return users.find_one(_id: update_user_id).to_json
end

post '/user/old' do
	# input
	user_id_email = params[:user_id]

	# downcasing the emails (to avoid issues of uppercase/lowercase emails)
	user_id_email.downcase!
	
	logger.info "Creating a new user with email <" + user_id_email + ">"

	users = settings.db.collection("Users")

	# Check if this email already exists
	user = users.find_one({_id: user_id_email})

	if user then
		# user if this email already exists
		logger.info "User already exists with id <" + user_id_email + ">. Returnig the existing user"
	else
		# Creating a new user
		user = {_id: user_id_email, is_public: true};
		user_id = users.save(user)
		logger.info "New user saved in the DB with user_id <" + user_id.to_s + ">"
	end

	# Returning the user
	result = user.to_json
end

# Updating user details
put '/user/old' do
	# input
	logger.debug "params for put /user: " + params.to_s 
	user_id_email = params[:user_id]
	is_public = params[:is_public]

	logger.info "Updating user with email <" + user_id_email + ">"
	users = settings.db.collection("Users")

	if is_public == "YES" then
		is_public = true
	elsif is_public == "NO" then
		is_public = false
	end

	users.update({_id: user_id_email}, {"$set" => {is_public: is_public}})
	
	# Returning the updated remake
	user = users.find_one(_id: user_id_email).to_json
end


# Creating a new remake (params are: story_id, user_id)
post '/remake' do
	# input
	story_id = BSON::ObjectId.from_string(params[:story_id])
	if BSON::ObjectId.legal?(params[:user_id]) then
		user_id = BSON::ObjectId.from_string(params[:user_id])
	else
		user_id = params[:user_id]
	end
	resolution = params[:resolution]

	remakes = settings.db.collection("Remakes")
	story = settings.db.collection("Stories").find_one(story_id)
	remake_id = BSON::ObjectId.new
	
	logger.info "Creating a new remake for story <" + story["name"] + "> for user <" + user_id.to_s + "> with remake_id <" + remake_id.to_s + ">"

	s3_folder = "Remakes" + "/" + remake_id.to_s + "/"
	s3_video = s3_folder + story["name"] + "_" + remake_id.to_s + ".mp4"
	s3_thumbnail = s3_folder + story["name"] + "_" + remake_id.to_s + ".jpg"

	remake = {_id: remake_id, story_id: story_id, user_id: user_id, created_at: Time.now ,status: RemakeStatus::New, 
		thumbnail: story["thumbnail"], video_s3_key: s3_video, thumbnail_s3_key: s3_thumbnail}

	# Creating the footages place holder based on the scenes of the story
	scenes = story["scenes"]
	if scenes then
		footages = Array.new
		for scene in scenes do			
			s3_destination_raw = s3_folder + "raw_" + "scene_" + scene["id"].to_s + ".mov"
			s3_destination_processed = s3_folder + "processed_" + "scene_" + scene["id"].to_s + ".mov"
			footage = {scene_id: scene["id"], status: FootageStatus::Open, raw_video_s3_key: s3_destination_raw, processed_video_s3_key: s3_destination_processed}
			footages.push(footage)
		end
		remake[:footages] = footages
	end

	#Creating the text place holder based the texts of the storu
	texts = story["texts"]
	if texts then
		text_inputs = Array.new
		for text in texts
			text_input = {text_id: text["id"]}
			text_inputs.push(text_input)
		end
		remake[:texts] = text_inputs
	end

	if resolution then
		remake[:resolution] = resolution
	end

	# Creating a new remake document in the DB
	remake_objectId = remakes.save(remake)

	logger.info "New remake saved in the DB with remake id " + remake_objectId.to_s

	# Creating a new directory in the remakes folder
	#remake_folder = settings.remakes_folder + remake_objectId.to_s
	#FileUtils.mkdir remake_folder

	# Returning the remake object ID
	result = remake.to_json
end

# Reporting this 
post '/remake/report' do
	# input
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	user_id = BSON::ObjectId.from_string(params[:user_id])

	remakes = settings.db.collection("Remakes")

	report = {reported_at: Time.now, user_id: user_id}
	remakes.update({_id: remake_id}, {"$push" => {reports: report}})

	# returning the remake object
	result = remakes.find_one(remake_id).to_json
end

# Deletes a given remake
delete '/remake/:remake_id' do
	# input
	remake_id = BSON::ObjectId.from_string(params[:remake_id])

	logger.info "Deleting (marking as deleted) remake " + remake_id.to_s

	# Updating the DB that this remake is marked as deleted
	remakes = settings.db.collection("Remakes")
	remakes.update({_id: remake_id}, {"$set" => {status: RemakeStatus::Deleted}})
	#settings.db.collection("Remakes").remove({_id: remake_id})

	remake = remakes.find_one(remake_id)

	
	# Updating the number of remakes for the story in another thread
	Thread.new{
		update_story_remakes_count(remake["story_id"])
	}

	# Returning the updated remake
	result = remake.to_json
end

# Returns a given remake id
get '/remake/:remake_id' do
	cache_control :no_cache

	# input
	remake_id = BSON::ObjectId.from_string(params[:remake_id])

	logger.info "Getting remake with id " + remake_id.to_s

	# Fetching the remake
	remakes = settings.db.collection("Remakes")
	remake = remakes.find_one(remake_id)

	if remake then
		remake.to_json
	else
		status 404
	end
end

# Returns all the remakes of a given user_id
get '/remakes/user/:user_id' do
	# input
	if BSON::ObjectId.legal?(params[:user_id]) then
		user_id = BSON::ObjectId.from_string(params[:user_id])
	else
		user_id = params[:user_id]
	end

	logger.info "Getting remakes for user " + user_id.to_s

	# Returning all the remakes of the given user and those with status inProgress, Rendering, Done and Timeout
	remakes_docs = settings.db.collection("Remakes").find({user_id: user_id, status: {"$in" => [RemakeStatus::InProgress, RemakeStatus::Rendering, RemakeStatus::Done, RemakeStatus::Timeout]}});

	remakes_json_array = Array.new
	for remake_doc in remakes_docs do
		remakes_json_array.push(remake_doc.to_json)
	end

	logger.info "Returning " + remakes_json_array.count.to_s + " remakes"

	remakes = "[" + remakes_json_array.join(",") + "]"
end

# Returns all the public remakes of a given story
get '/remakes/story/:story_id' do
	# input
	story_id = BSON::ObjectId.from_string(params[:story_id])

	logger.info "Getting remakes for story " + story_id.to_s

	# Getting all the public users
	public_users_cursor = settings.db.collection("Users").find({is_public:true})
	public_users = Array.new

	for user in public_users_cursor do
		public_users.push(user["_id"])
	end

	story_ids = Array.new
	story_ids.push(story_id)

	story = settings.db.collection("Stories").find_one(story_id)
	if story["story_480"] then		
		story_ids.push(story["story_480"])
	end

	# Getting all the completed remakes of the public users
	remakes_docs = settings.db.collection("Remakes").find({story_id:{"$in" => story_ids}, status: RemakeStatus::Done, user_id:{"$in" => public_users}});

	remakes_json_array = Array.new
	for remake_doc in remakes_docs do
		remakes_json_array.push(remake_doc.to_json)
	end

	logger.info "Returning " + remakes_json_array.count.to_s + " remakes for story " + story_id.to_s

	remakes = "[" + remakes_json_array.join(",") + "]"
end

def update_story_remakes_count(story_id)
	remakes = settings.db.collection("Remakes")
	stories = settings.db.collection("Stories")

	story = stories.find_one(story_id)

	# Getting the number of remakes for this story
	story_remakes = remakes.count({query: {story_id: story_id, status: RemakeStatus::Done}})
	if story["story_480"] then
		story_480_remakes = remakes.count({query: {story_id: story["story_480"], status: RemakeStatus::Done}})
		story_remakes += story_480_remakes
	end

	stories.update({_id: story_id}, {"$set" => {"remakes_num" => story_remakes}})
	logger.info "Updated story id <" + story_id.to_s + "> number of remakes to " + story_remakes.to_s
end

get '/test/update/remakes/:story_id' do
	story_id = BSON::ObjectId.from_string(params[:story_id])

	update_story_remakes_count story_id
end


get '/test/text' do
	form = '<form action="/text" method="post" enctype="multipart/form-data"> Remake ID: <input type="text" name="remake_id"> Text ID: <input type="text" name="text_id"> Text: <input type="text" name="text"> <input type="submit" value="Text!"> </form>'
	erb form
end

post '/text' do
	#input
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	text_id = params[:text_id].to_i	
	text = params[:text]

	puts "Text <" + text + "> applied for remake <" + remake_id.to_s + "> text_id <" + text_id.to_s + ">"

	remakes = settings.db.collection("Remakes")
	result = remakes.update({_id: remake_id, "texts.text_id" => text_id}, {"$set" => {"texts.$.text" => text}})

	# Returning the remake after the DB update
	remake = remakes.find_one(remake_id).to_json
end

# Post a new footage (params are: uploaded file, remake id, scene id)
post '/footage' do
	# input
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	scene_id = params[:scene_id].to_i
	take_id = params[:take_id]

	if !take_id then
		take_id = ""
	end

	logger.debug "Footage " + scene_id.to_s + " of Remake " + remake_id.to_s + " with take id " + take_id + " uploaded and now will be processed"

	new_footage(remake_id, scene_id, take_id)

	# Returning the remake after the DB update
	remake = settings.db.collection("Remakes").find_one(remake_id).to_json
end

put '/footage' do
	# input
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	scene_id = params[:scene_id].to_i
	take_id = params[:take_id]

	remakes = settings.db.collection("Remakes")

	# Updating the remake with the new take id + changing the status
	result = remakes.update({_id: remake_id, "footages.scene_id" => scene_id}, {"$set" => {"footages.$.take_id" => take_id, "footages.$.status" => FootageStatus::Uploaded}})
	logger.info "Update for remake <" + remake_id.to_s + ">, footage <" + scene_id.to_s + "> with new take_id <" + take_id + ">"  

	# Returning the remake after the DB update
	remake = settings.db.collection("Remakes").find_one(remake_id).to_json
end

def to_boolean(str)
	!!(str =~ /^(true|t|yes|y|1)$/i)
end


def new_footage (remake_id, scene_id, take_id)
	logger.info "New footage for scene " + scene_id.to_s + " for remake " + remake_id.to_s + " with take_id " + take_id

	# Fetching the remake for this footage
	remakes = settings.db.collection("Remakes")

	# Updating the status of this remake to in progress
	remakes.update({_id: remake_id}, {"$set" => {status: RemakeStatus::InProgress}})

	# Updating the status of this footage to uploaded
	result = remakes.update({_id: remake_id, "footages.scene_id" => scene_id}, {"$set" => {"footages.$.status" => FootageStatus::Uploaded}})
	#logger.debug "DB Result: " + result.to_s
	logger.info "Footage status updated to Uploaded (1) for remake <" + remake_id.to_s + ">, footage <" + scene_id.to_s + ">"

	Thread.new{
		# Running the foreground extraction algorithm
		#foreground_extraction remake_id, scene_id
		### Call honage-server-foreground

		logger.info "Calling homage-server-foreground"
		response = Net::HTTP.post_form(settings.homage_server_foreground_uri, {"remake_id" => remake_id.to_s, "scene_id" => scene_id.to_s, "take_id" => take_id})
		logger.debug "Response from homage-server-foreground" + response.to_s
	}
end

def is_remake_ready (remake_id)
	remake = settings.db.collection("Remakes").find_one(remake_id)
	is_ready = true

	for footage in remake["footages"] do
		if footage["status"] != FootageStatus::Ready 
			is_ready = false;
		end
	end

	return is_ready
end

def send_movie_ready_push_notification(story, remake)
	user_id = remake["user_id"]
	alert = "Your " + story["name"] + " movie is ready!"
	custom_data = {type: PushNotifications::MovieReady, remake_id: remake["_id"].to_s, story_id: story["_id"].to_s}

	send_push_notification_to_user(user_id, alert, custom_data)
end

def send_movie_timeout_push_notification(remake)
	user_id = remake["user_id"]
	alert = "Failed to create your movie, open the application and try again"
	custom_data = {type: PushNotifications::MovieTimout, remake_id: remake["_id"].to_s, story_id: remake["story_id"].to_s}

	send_push_notification_to_user(user_id, alert, custom_data)
end

def send_push_notification_to_user(user_id, alert, custom_data)
	logger.debug "send_push_notification_to_user: " + user_id.to_s + "; " + alert + "; " + custom_data.to_s

	# If this is the old user id (not an ObjectId, then returning)
	if !BSON::ObjectId.legal?(user_id.to_s) then
		logger.debug "not legal"
		return
	end

	token_used = Set.new

	# Getting the user of this remake and pushing a notification to all his devices
	users = settings.db.collection("Users")
	user = users.find_one(user_id)
	for device in user["devices"] do
		if device.has_key?("push_token")
			token = device["push_token"]
			if !token_used.include?(token) then
				send_push_notification(token, alert, custom_data)
				token_used.add(token)
			end
		end
	end
end

def send_push_notification(device_token, alert, custom_data)
	logger.info "Sending push notification to device token: " + device_token.to_s + " with alert: " + alert + " with custom_data: " + custom_data.to_s
	notification = Houston::Notification.new(device: device_token)
	notification.alert = alert
	notification.custom_data = custom_data
	notification.sound = "default"
	APN.push(notification)	
end


post '/render' do
	# input
	remake_id = BSON::ObjectId.from_string(params[:remake_id])

	# Updating the DB that the process has started
	remakes = settings.db.collection("Remakes")
	remakes.update({_id: remake_id}, {"$set" => {status: RemakeStatus::Rendering, render_start:Time.now}})

	Thread.new{
		# Waiting until this remake is ready for rendering (or there is a timout)
		is_ready = is_remake_ready remake_id 
		sleep_for = 900
		sleep_duration = 5
		while ! is_ready && sleep_for > 0 do
			logger.info "Waiting for remake " + remake_id.to_s + " to be ready"
			sleep sleep_duration
			sleep_for -= sleep_duration
			is_ready = is_remake_ready remake_id
		end

		if is_ready then
			# Synchronizing the actual rendering (because we cannot have more than 1 rendering in parallel)
			# if settings.rendering_semaphore.locked? then
			# 	logger.info "Rendering for remake " + remake_id.to_s + " waiting for other threads to finish rendering"
			# else
			# 	logger.debug "Rendering is going to start for remake " + remake_id.to_s
			# end	

			logger.info "Calling homage-server-render"
			response = Net::HTTP.post_form(settings.homage_server_render_uri, {"remake_id" => remake_id.to_s})
			logger.info "homage-server-render " + response.to_s

			# settings.rendering_semaphore.synchronize{
			# 	render_video remake_id
			# }
		else
			logger.warn "Timeout on the rendering of remake <" + remake_id.to_s + "> - updating DB"
			result = remakes.update({_id: remake_id}, {"$set" => {status: RemakeStatus::Timeout}})
			logger.info "DB update result: " + result.to_s
			remake = remakes.find_one(remake_id)			
			send_movie_timeout_push_notification(remake)
		end
	}

	remake = remakes.find_one(remake_id).to_json
end

get '/test/logger' do
	logger.debug "Log debug test"
	logger.info "Log info test"
	logger.warn "Log warn test"
	logger.error "Log error test"
	logger.fatal "Log fatal test"
end

get '/test/render' do
	form = '<form action="/render" method="post" enctype="multipart/form-data"> Remake ID: <input type="text" name="remake_id"> <input type="submit" value="Render!"> </form>'
	erb form
end

get '/test/foreground' do
	form = '<form action="/footage" method="post" enctype="multipart/form-data"> Remake ID: <input type="text" name="remake_id"> Scene ID: <input type="text" name="scene_id"> <input type="submit" value="Upload!"> </form>'
	erb form
end

post '/update_text' do
	dynamic_text_path = settings.aeProjectsFolder + params[:template_folder] + "/" + params[:dynamic_text_file]
	dynamic_text = params[:dynamic_text]
	#file_contents = "var Text = ['#{dynamic_text}'];"
	file_contents = '"' + dynamic_text + '"'

	dynamic_text_file = File.new(dynamic_text_path, "w")
    dynamic_text_file.puts(file_contents)
    dynamic_text_file.close

    'Text updated!'
    #redirect back
end

get '/download/:filename' do
	downloadPath = settings.outputFolder + params[:filename]
	puts "download file path: #{downloadPath}"
	send_file downloadPath #, :type => 'video/mp4', :disposition => 'inline'
end

get '/play/intro' do
	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	erb :intro
end

#get '/play/DemoDay' do
get %r{^/play/diveschool/?$}i do
	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	dive_school_story_id = BSON::ObjectId.from_string("52de83db8bc427751c000305")
	#@remakes = settings.db.collection("Remakes").find({story_id: dive_school_story_id, status:RemakeStatus::Done})
	@remakes = settings.db.collection("Remakes").find({story_id: dive_school_story_id, demo:true}).sort(_id: 1)
	@heading = "Dive School"
	@grade = false

	erb :demoday
end 

get '/play/date/:from_date' do
	from_date = Time.parse(params[:from_date])

	@remakes = settings.db.collection("Remakes").find(created_at:{"$gte"=>from_date}, status:3).sort(created_at:-1)
	@heading = @remakes.count.to_s + " Remakes from " + from_date.strftime("%d/%m/%Y")
	@grade = true

	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	erb :demoday
end

get '/play/public/date/:from_date' do
	from_date = Time.parse(params[:from_date])

	# Getting all the public users
	public_users_cursor = settings.db.collection("Users").find({is_public:true})
	public_users = Array.new

	for user in public_users_cursor do
		public_users.push(user["_id"])
	end

	# Getting all the completed remakes of the public users
	@remakes = settings.db.collection("Remakes").find({created_at:{"$gte"=>from_date}, status: RemakeStatus::Done, user_id:{"$in" => public_users}}).sort(created_at:-1)
	@heading = @remakes.count.to_s + " Public Remakes from " + from_date.strftime("%d/%m/%Y")
	@grade = true

	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	erb :demoday
end


post '/update/grade' do
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	grade = params[:grade].to_i

	logger.info "updating grade for remake " + remake_id.to_s + " to grade " + grade.to_s

	remakes = settings.db.collection("Remakes")
	remakes.update({_id: remake_id}, {"$set" => {grade: grade}})

	redirect back
end


#analytics routes
post '/remake/share' do
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	user_id =  BSON::ObjectId.from_string(params[:user_id])
	share_method = params[:share_method].to_i

	logger.info "creating share entity for Remake " + remake_id.to_s + " for user " + user_id.to_s

	shares = settings.db.collection("Shares")
	share = {user_id:user_id , remake_id:remake_id, share_method:share_method, created_at:Time.now }
	share_objectId = shares.save(share)
	logger.info "New share saved in the DB with share id " + share_objectId.to_s
	return share.to_json
end




get '/play/deleted/date/:from_date' do
	from_date = Time.parse(params[:from_date])

	@remakes = settings.db.collection("Remakes").find(created_at:{"$gte"=>from_date}, status:5).sort(created_at:-1)
	@heading = @remakes.count.to_s + " Remakes from " + from_date.strftime("%d/%m/%Y")
	@grade = false

	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	erb :demoday
end

get '/play/stories' do
	superior_man_id = BSON::ObjectId.from_string("535e8fc981360cd22f0003d4")

	# Getting all the public users
	public_users_cursor = settings.db.collection("Users").find({is_public:true})
	public_users = Array.new
	for user in public_users_cursor do
		public_users.push(user["_id"])
	end

	@stories = settings.db.collection("Stories").find(active:true)

	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	erb :stories
end

get '/play/story/:story_id' do
	story_id = BSON::ObjectId.from_string(params[:story_id])

	# Getting all the public users
	public_users_cursor = settings.db.collection("Users").find({is_public:true})
	public_users = Array.new
	for user in public_users_cursor do
		public_users.push(user["_id"])
	end

	@remakes = settings.db.collection("Remakes").find(story_id:story_id, status:RemakeStatus::Done, grade:{"$gte"=>1}, user_id:{"$in" => public_users}).sort(grade:-1)

	@heading = settings.db.collection("Stories").find_one(story_id)["name"]

	@grade = false

	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	erb :demoday
end


get '/play/:remake_id' do
	remake_id = BSON::ObjectId.from_string(params[:remake_id])

	remakes = settings.db.collection("Remakes")
	@remake = remakes.find_one(remake_id)

	users = settings.db.collection("Users")
	if BSON::ObjectId.legal?(@remake["user_id"]) then
		@user = users.find_one(@remake["user_id"])
	else
		@user = users.find_one({_id: @remake["user_id"]})
	end

	stories = settings.db.collection("Stories")
	@story = stories.find_one(@remake["story_id"])

	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	erb :video
end

get '/health/check' do
end

get '/test/env' do
	x = ENV['RACK_ENV']
end

get '/test/error' do
	hash = { :message => 'good error', :error_code => 12345 }
	[500, [hash.to_json]]
end

get '/test/push/:user_id' do
	user_id = BSON::ObjectId.from_string(params[:user_id])
	alert = "How many notifications?"
	custom_data = {type: 0, remake_id: "kjfdkjf333kj3kj3kj3"}
	
	send_push_notification_to_user(user_id, alert, custom_data)

	"done"
end
