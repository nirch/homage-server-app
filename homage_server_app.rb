#encoding: utf-8
require 'sinatra'
require 'mongo'
require 'uri'
require 'json'
require 'open-uri'
require 'logger'
require 'net/http'

configure do
	# Global configuration (regardless of the environment)

end

configure :production do
	# Production DB connection
	db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod")
	set :db, db_connection.db()

	# Production AE server connection
	set :homage_server_foreground_uri, URI.parse("http://54.235.111.163:4567/footage")
	set :homage_server_render_uri, URI.parse("http://54.235.111.163:4567/render")

	set :logging, Logger::INFO
end

configure :test do
	# Test DB connection
	db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage")
	set :db, db_connection.db()

	# Test AE server connection
	set :homage_server_foreground_uri, URI.parse("http://54.83.32.172:4567/footage")
	set :homage_server_render_uri, URI.parse("http://54.83.32.172:4567/render")

	set :logging, Logger::DEBUG
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

# Get all stories
get '/stories' do
	stories_collection = settings.db.collection("Stories")
	stories_docs = stories_collection.find({active: true}, {fields: {after_effects: 0}}).sort({order_id: 1})

	stories_json_array = Array.new
	for story_doc in stories_docs do
		stories_json_array.push(story_doc.to_json)
	end

	logger.info "Returning " + stories_json_array.count.to_s + " stories"

	stories = "[" + stories_json_array.join(",") + "]"
	# stories = JSON[stories_docs]
end

get '/test/user' do
	form = '<form action="/user" method="post" enctype="multipart/form-data"> e-mail: <input type="text" name="user_id"> <input type="submit" value="Create User"> </form>'
	erb form
end

def handle_facebook_login(user)
	# Facebook user, starting with a check if this is a signup or login
	facebook_id = user["facebook"]["id"]

	users = settings.db.collection("Users")
	user_exists = users.find_one({"facebook.id" => facebook_id})

	if user_exists then
		logger.info "Facebook user exists with id <" + user_exists.to_s + ">. returning existing user"
		return user_exists
	else
		new_user_id = users.save(user)	
		logger.info "New facebook user saved in the DB with user_id <" + new_user_id.to_s + ">"
		new_user = users.find_one(new_user_id)
		return new_user
	end
end

def handle_guest_login(user)
	users = settings.db.collection("Users")
	new_user_id = users.save(user)
	logger.info "New guest user saved in the DB with user_id <" + new_user_id.to_s + ">"
	new_user = users.find_one(new_user_id)
end

post '/user/v2' do
	# input
	new_user = params

	logger.info "POST /user with params <" + params.to_s + ">"

	# Converting is_public to boolean (default is false)
	if new_user["is_public"] then
		new_user["is_public"] = to_boolean new_user["is_public"]
	else
		new_user["is_public"] = false
	end

	# Handeling the differnet logins: facebook; email; guest
	if new_user["facebook"] then
		user = handle_facebook_login new_user
	else
		user = handle_guest_login new_user
	end

	# Returning the user
	result = user.to_json
end

post '/user' do
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
put '/user' do
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
	user_id = params[:user_id]

	remakes = settings.db.collection("Remakes")
	story = settings.db.collection("Stories").find_one(story_id)
	remake_id = BSON::ObjectId.new
	
	logger.info "Creating a new remake for story <" + story["name"] + "> for user <" + user_id + "> with remake_id <" + remake_id.to_s + ">"

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

	# Creating a new remake document in the DB
	remake_objectId = remakes.save(remake)

	logger.info "New remake saved in the DB with remake id " + remake_objectId.to_s

	# Creating a new directory in the remakes folder
	#remake_folder = settings.remakes_folder + remake_objectId.to_s
	#FileUtils.mkdir remake_folder

	# Returning the remake object ID
	result = remake.to_json
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
	
	# Returning the updated remake
	remake = remakes.find_one(remake_id).to_json
end

# Returns a given remake id
get '/remake/:remake_id' do
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
	user_id = params[:user_id];

	logger.info "Getting remakes for user " + user_id

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

	# Getting all the completed remakes of the public users
	remakes_docs = settings.db.collection("Remakes").find({story_id: story_id, status: RemakeStatus::Done, user_id:{"$in" => public_users}});

	remakes_json_array = Array.new
	for remake_doc in remakes_docs do
		remakes_json_array.push(remake_doc.to_json)
	end

	logger.info "Returning " + remakes_json_array.count.to_s + " remakes for story " + story_id.to_s

	remakes = "[" + remakes_json_array.join(",") + "]"
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

	new_footage remake_id, scene_id

	# Returning the remake after the DB update
	remake = settings.db.collection("Remakes").find_one(remake_id).to_json
end

def to_boolean(str)
	!!(str =~ /^(true|t|yes|y|1)$/i)
end


def new_footage (remake_id, scene_id)
	logger.info "New footage for scene " + scene_id.to_s + " for remake " + remake_id.to_s

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
		response = Net::HTTP.post_form(settings.homage_server_foreground_uri, {"remake_id" => remake_id.to_s, "scene_id" => scene_id.to_s})
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

post '/render' do
	# input
	remake_id = BSON::ObjectId.from_string(params[:remake_id])

	# Updating the DB that the process has started
	remakes = settings.db.collection("Remakes")
	remakes.update({_id: remake_id}, {"$set" => {status: RemakeStatus::Rendering}})

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
			remakes.update({_id: remake_id}, {"$set" => {status: RemakeStatus::Timeout}})
			logger.debug "DB update result: " + result.to_s
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
	form = '<form action="/test/foreground" method="post" enctype="multipart/form-data"> Remake ID: <input type="text" name="remake_id"> Scene ID: <input type="text" name="scene_id"> <input type="submit" value="Upload!"> </form>'
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
	erb :demoday
end 

get '/play/:remake_id' do
	remake_id = BSON::ObjectId.from_string(params[:remake_id])

	remakes = settings.db.collection("Remakes")
	@remake = remakes.find_one(remake_id)

	stories = settings.db.collection("Stories")
	@story = stories.find_one(@remake["story_id"])

	headers \
		"X-Frame-Options"   => "ALLOW-FROM http://play.homage.it/"

	erb :video
end

get '/test/env' do
	x = ENV['RACK_ENV']
end

get '/test/error' do
	hash = { :message => 'good error', :error_code => 12345 }
	[500, [hash.to_json]]
end
