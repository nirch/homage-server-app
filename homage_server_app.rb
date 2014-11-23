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
require 'chartkick'
require 'aws-sdk'
require 'active_support/core_ext'
require 'user_agent_parser'
require 'sinatra/subdomain'
require 'mixpanel-ruby'
require 'mail'
require 'zip'
require File.expand_path '../mongo scripts/Analytics.rb', __FILE__

current_session_ID = nil

configure do
	# Global configuration (regardless of the environment)
	aws_config = {access_key_id: "AKIAJTPGKC25LGKJUCTA", secret_access_key: "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"}
	AWS.config(aws_config)

	# Using Amazon's SES for mail delivery
	Mail.defaults do
  		delivery_method :smtp, { 
		    :address => 'email-smtp.us-east-1.amazonaws.com',
		    :port => '587',
		    :user_name => 'AKIAI2R3CISWP2RWKJGA',
		    :password => 'At7lxX0rtF3814Kr4mwrZTWO39kFZ1Kg+iRMhi1pjWPp',
		    :authentication => :plain,
		    :enable_starttls_auto => true
		  }
	end
end

configure :production do
	# Production DB connection
	db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod")
	set :db, db_connection.db()

	# Push notification certificate
	APN = Houston::Client.production
	APN.certificate = File.read(File.expand_path("../certificates/homage_push_notification_prod.pem", __FILE__))
	APN.passphrase = "homage"

	APN_NEW = Houston::Client.production
	APN_NEW.certificate = File.read(File.expand_path("../certificates/homage_push_notification_prod_150.pem", __FILE__))
	APN_NEW.passphrase = "homage"

	# Process Footage Queue
	process_footage_queue_url = "https://sqs.us-east-1.amazonaws.com/509268258673/ProcessFootageQueue"
    set :process_footage_queue, AWS::SQS.new.queues[process_footage_queue_url]

	# Production AE server connection
	set :homage_server_foreground_uri, URI.parse("http://homage-render-prod-elb-882305239.us-east-1.elb.amazonaws.com:4567/footage")
	set :homage_server_render_uri, URI.parse("http://homage-render-prod-elb-882305239.us-east-1.elb.amazonaws.com:4567/render")

	# Setting MixPanel only in prodution
	set :mixpanel, Mixpanel::Tracker.new("7d575048f24cb2424cd5c9799bbb49b1")

	set :logging, Logger::INFO

	set :share_link_prefix, "http://play.homage.it"

	set :play_subdomain, :play
end

configure :test do
	# Test DB connection
	db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage")
	set :db, db_connection.db()

	# Push notification certificate
	APN = Houston::Client.development
	APN.certificate = File.read(File.expand_path("../certificates/homage_push_notification_dev.pem", __FILE__))

	APN_NEW = Houston::Client.production
	APN_NEW.certificate = File.read(File.expand_path("../certificates/homage_push_notification_prod_150.pem", __FILE__))
	APN_NEW.passphrase = "homage"

	# Process Footage Queue
	process_footage_queue_url = "https://sqs.us-east-1.amazonaws.com/509268258673/ProcessFootageQueueTest"
    set :process_footage_queue, AWS::SQS.new.queues[process_footage_queue_url]

	# Test AE server connection
	set :homage_server_foreground_uri, URI.parse("http://54.83.32.172:4567/footage")
	set :homage_server_render_uri, URI.parse("http://54.83.32.172:4567/render")
	set :logging, Logger::DEBUG

	set :share_link_prefix, "http://play-test.homage.it"

	# enables mixpanel for testing
	# set :mixpanel, Mixpanel::Tracker.new("7d575048f24cb2424cd5c9799bbb49b1")

	set :play_subdomain, :'play-test'
end

before do
	logger.debug "request.env: " + request.env.to_s
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
	InvalidDeviceID = 1006
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
	MessageShareMethod = 4
	WeiboShareMethod = 5
	TwitterShareMethod = 6
	GooglePlusShareMethod = 7
	PinterestShareMethod = 8

end

module PlaybackEventType
	PlaybackEventStart = 0
	PlaybackEventStop = 1
end

module KPIGraphType
	NormalFractionGraphType = 0
	NormalValueGraphType = 1
	AvgValueGraphType = 2
	StoryViewsGraphType = 3
	PieChartGraphType = 4
	UndefinedGraphType = 5
end

module ViewSource
	IPhoneApp  = 0
	AndroidApp = 1
	Desktop    = 2
	Mobile     = 3
	Unknown    = 4
end

module AppInstallFrom
	AppInvite = "AppInvite"
	MiniSite  = "MiniSite"
	HomageSite = "HomageSite"
end

module RemakesQueryType
	AllQuery      = 0
	StoryQuery    = 1
  	MyTakesQuery  = 2
  	TrendingQuery = 3
end

get '/remakes' do
		# input
		skip = params[:skip].to_i if params[:skip] # Optional
		limit = params[:limit].to_i if params[:limit] # Optional
		campaign_id = BSON::ObjectId.from_string(params[:campaign_id]) if params[:campaign_id] #optional
		query_type = params[:query_type].to_i if params[:query_type]

		
		story_names = params["stories"] if params["stories"];
		story_id_array = Array.new
		story_find_condition = {active: true}

		if story_names then
			for name in story_names do
				story = settings.db.collection("Stories").find_one({name: name})
				story_id_array.push(story["_id"])
			end
			story_find_condition["_id"] = {"$in"=> story_id_array}
		end

		if campaign_id then
			story_find_condition["campaign_id"] = campaign_id
		end

		stories = settings.db.collection("Stories").find(story_find_condition, {fields: {after_effects: 0}}) 
	
		story_names = Hash.new
		for story in stories do
			story_id = story["_id"]
			story_names["story_id"] = story["name"]
		end

		# Getting all the public users
		public_users_cursor = settings.db.collection("Users").find({is_public:true})
		public_users = Array.new

		for user in public_users_cursor do
			public_users.push(user["_id"])
		end

		# build mongodb aggregation pipeline accroding to query type from client
		######################################################################################
		aggregation_pipeline = []
		
		find_condition = {status: RemakeStatus::Done, user_id:{"$in" => public_users}, grade:{"$ne" => -1}}
		if story_id_array.length != 0 then
			find_condition["story_id"] = {"$in"=> story_id_array}
		end

		if query_type == RemakesQueryType::MyTakesQuery then
			#once we have a user (user! not cookie) replace the find_condition "user_id:"
		end

		remakes_find_condition = {"$match" => find_condition}
		aggregation_pipeline.push(remakes_find_condition)
	    
		if query_type == RemakesQueryType::TrendingQuery then
			share_weight = 0.5
			like_weight = 0.4
			view_weight = 0.1

		    trending_proj={"$project" => {"_id" => 1, "created_at" => 1, "grade" => 1, "share_count" => 1, "share_link" => 1, "significant_views" => 1, "status" => 1, "story_id" => 1, "thumbnail" => 1, "unique_significant_views" => 1, "unique_views" => 1, "unique_web_impressions" => 1, "user_id" => 1, "video" => 1, "views" => 1, "web_impressions" => 1, "like_count" => 1,
		    	"trending_score" => {"$add" => [{"$multiply" => ["$like_count",like_weight]},{"$multiply" => ["$share_count",share_weight]},{"$multiply" => ["$views",view_weight]}]}}}

		    sort = {"$sort" => {"trending_score" => -1}}

		    aggregation_pipeline.push(trending_proj)
		    aggregation_pipeline.push(sort)
		else
			sort = {"$sort" => {"created_at" => -1, "grade" => -1}}
			aggregation_pipeline.push(sort)
		end

		skip  = {"$skip" => skip}
		aggregation_pipeline.push(skip)
		limit = {"$limit" => limit}
		aggregation_pipeline.push(limit)
               
	    remakes = settings.db.collection("Remakes").aggregate(aggregation_pipeline)
		
		logger.debug "number of remakes returned:"
		logger.debug remakes.count

		remakes_result = Array.new;
		for remake in remakes do
			story_id = remake["story_id"]
			logger.debug "remake: " + remake["_id"].to_s + " trend score: " + remake["trending_score"].to_s
			story_name = story_names[story_id];
			remake["story_name"] = story_name;
			remakes_result.push(remake);
		end

		remakes_result = remakes_result.to_json
end

get '/ios' do
 	shared_from = "Undefined"
	shared_from = params[:src] if params[:src]
	origin_id = params[:origin_id] if params[:origin_id]

	info = Hash.new
	info["shared_from"] = shared_from
	info["origin_id"] = origin_id if origin_id

	settings.mixpanel.track("12345", "InstalliOS", info) if settings.respond_to?(:mixpanel)	
	redirect "https://itunes.apple.com/us/app/id851746600", 302
end

get '/android' do
	shared_from = "Undefined"
	shared_from = params[:src] if params[:src]
	origin_id = params[:origin_id] if params[:origin_id]

	info = Hash.new
	info["shared_from"] = shared_from
	info["origin_id"] = origin_id if origin_id

	settings.mixpanel.track("12345", "InstallAndroid", info) if settings.respond_to?(:mixpanel)	
	redirect "https://play.google.com/store/apps/details?id=com.homage.app", 302
end

get '/raw/date/:from_date' do
	from_date = Time.parse(params[:from_date])

	@remakes = settings.db.collection("Remakes").find(created_at:{"$gte"=>from_date}, status:3).sort(created_at:-1)
	@heading = @remakes.count.to_s + " Remakes from " + from_date.strftime("%d/%m/%Y")
	@grade = true

	erb :demodayraw
end


#################
# Play Subdomain
#################

subdomain settings.play_subdomain do
	get '/intro' do
		erb :intro
	end

	#get '/play/DemoDay' do
	get %r{^/diveschool/?$}i do
		dive_school_story_id = BSON::ObjectId.from_string("52de83db8bc427751c000305")
		#@remakes = settings.db.collection("Remakes").find({story_id: dive_school_story_id, status:RemakeStatus::Done})
		@remakes = settings.db.collection("Remakes").find({story_id: dive_school_story_id, demo:true}).sort(_id: 1)
		@heading = "Dive School"
		@grade = false

		erb :demoday
	end 

	get '/date/:from_date' do
		from_date = Time.parse(params[:from_date])

		@remakes = settings.db.collection("Remakes").find(created_at:{"$gte"=>from_date}, status:3).sort(created_at:-1)
		@heading = @remakes.count.to_s + " Remakes from " + from_date.strftime("%d/%m/%Y")
		@grade = true

		erb :demoday
	end

	get '/public/date/:from_date' do
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

		erb :demoday
	end

	#play routes
	get '/deleted/date/:from_date' do
		from_date = Time.parse(params[:from_date])

		@remakes = settings.db.collection("Remakes").find(created_at:{"$gte"=>from_date}, status:5).sort(created_at:-1)
		@heading = @remakes.count.to_s + " Remakes from " + from_date.strftime("%d/%m/%Y")
		@grade = false

		erb :demoday
	end

	get '/stories' do
		superior_man_id = BSON::ObjectId.from_string("535e8fc981360cd22f0003d4")

		# Getting all the public users
		public_users_cursor = settings.db.collection("Users").find({is_public:true})
		public_users = Array.new
		for user in public_users_cursor do
			public_users.push(user["_id"])
		end

		@stories = settings.db.collection("Stories").find(active:true)

		erb :stories
	end

	get '/story/:story_id' do
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

		erb :demoday
	end

	get '/minisite' do
		erb :HMGMiniSite
	end

	get '/gallery/:campaign_name' do
		@config = getConfigDictionary();
		@campaign = settings.db.collection("Campaigns").find_one({name: params[:campaign_name]})
		campaign_id = @campaign["_id"]
		@stories = settings.db.collection("Stories").find({active:true, campaign_id: campaign_id})
		erb :new_minisite
	end

	get '/:entity_id' do
		remakes = settings.db.collection("Remakes")
		users   = settings.db.collection("Users")
		shares  = settings.db.collection("Shares")
		stories = settings.db.collection("Stories")
		@config = getConfigDictionary();

		entity_id = BSON::ObjectId.from_string(params[:entity_id])
		@share  = shares.find_one(entity_id)
		if @share == nil then
			@remake = remakes.find_one(entity_id)
			@originating_share_id = ""
		else 
			remake_id = @share["remake_id"]
			@remake = remakes.find_one(remake_id)
			@originating_share_id = @share["_id"]
			shares.update({_id: @originating_share_id},{"$set" => {share_status: true}})
		end

		# story_id = @remake["story_id"]
		# logger.debug "story_id" + story_id.to_s
		# campaign_id = settings.db.collection("Stories").find_one({_id: story_id})["campaign_id"]
		# logger.debug "campaign_id: " + campaign_id.to_s
		# @campaign = settings.db.collection("Campaigns").find_one({_id: campaign_id})
		# campaign_id = @campaign["_id"]
		# @stories = settings.db.collection("Stories").find({active:true, campaign_id: campaign_id})
	
		if BSON::ObjectId.legal?(@remake["user_id"]) then
			@user = users.find_one(@remake["user_id"])
		else
			@user = users.find_one({_id: @remake["user_id"]})
		end

		@story = stories.find_one(@remake["story_id"])

		# erb :new_minisite
		erb :HMGVideoPlayer
	end
end

###################
# All Other Routes
###################

# Get all stories
get '/stories' do
	# input
	skip = params[:skip].to_i if params[:skip] # Optional
	limit = params[:limit].to_i if params[:limit] # Optional
	remakes_num = params[:remakes].to_i if params[:remakes] # Optional

	stories = settings.db.collection("Stories").find({}, {fields: {after_effects: 0}}).sort({order_id: 1})
	stories = stories.skip(skip) if skip
	stories = stories.limit(limit) if limit

	# Creating an array of all the public users (to use when getting the top remakes)
	if remakes_num && remakes_num > 0 then
		public_users_cursor = settings.db.collection("Users").find({is_public:true})
		public_users = Array.new
		for user in public_users_cursor do
			public_users.push(user["_id"])
		end
	end

	stories_json_array = Array.new
	for story in stories do
		# Allow story until proven otherwise
		allow_story = true

		# Checking if this story is filtered for specific users
		if story["active_users"] then
			user_id = params[:app_info][:user_id] if params[:app_info] && params[:app_info][:user_id]
			user_id = request.env["HTTP_USER_ID"].to_s if request.env["HTTP_USER_ID"]

			active_users = story["active_users"]
			if user_id then
				allow_story = false unless active_users.include?(user_id)
			else
				allow_story = false
			end
		end

		# Adding the remakes per story
		if allow_story && remakes_num && remakes_num > 0 then
			story_remakes = settings.db.collection("Remakes").find({story_id:story["_id"], status: RemakeStatus::Done, user_id:{"$in" => public_users}, grade:{"$ne" => -1}}).sort(grade:-1).limit(remakes_num);
			story[:remakes] = story_remakes.to_a
		end

		stories_json_array.push(story.to_json) if allow_story
	end

	logger.info "Returning " + stories_json_array.count.to_s + " stories"

	stories_result = "[" + stories_json_array.join(",") + "]"
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
		destination_devices.add(device["identifier_for_vendor"]) if device["identifier_for_vendor"]
		destination_devices.add(device["device_id"]) if device["device_id"]		
	end

	for device in source_user["devices"]
		if device["identifier_for_vendor"] then
			if !destination_devices.include?(device["identifier_for_vendor"]) then
				#logger.info "Adding to user " + destination_id.to_s + " device " + device.to_s 
				users.update({_id: destination_id}, {"$push" => {devices: device} })
			end
		elsif device["device_id"] then
			if !destination_devices.include?(device["device_id"]) then
				#logger.info "Adding to user " + destination_id.to_s + " device " + device.to_s 
				users.update({_id: destination_id}, {"$push" => {devices: device} })
			end
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
				updated_user = users.find_one(update_user_id)
				update_user_name_in_remakes(updated_user)
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

		# Checking if the password exists in the DB. If so procedding with the authentication. If not assuming that the password was reseted
		if user_exists["password_hash"]
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
			# Password was reset, saving the new password (after encrypting it)
			password_hash = Sinatra::Security::Password::Hashing.encrypt(user["password"])
			user.delete("password")
			users.update({_id: user_exists["_id"]}, {"$set" => {password_hash: password_hash}})
			logger.info "User <" + email + "> successfully authenticated with new password"
			return user_exists["_id"], nil, false
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

def user_name(user)
	if user["facebook"] then
		return user["facebook"]["name"]
	elsif user["email"] then
		# Getting the prefix of the email ("nir.channes" of "nir.channes@gmail.com")
		prefix = user["email"].split("@")[0]

		# Replacing dots '.' and underscores '_' with space
		prefix.gsub!('.', ' ')
		prefix.gsub!('_', ' ')

		# Capitalizing each word
		name = prefix.split.map(&:capitalize).join(' ')

		return name
	else
		return nil
	end
end

def update_user_name_in_remakes(user)
	username = user_name(user)

	return if !username

	remakes = settings.db.collection("Remakes").find({user_id:user["_id"]})
	logger.info "Going to update " + remakes.count.to_s + " remakes with the fullname: " + username
	for remake in remakes do
		logger.info "Updating remake " + remake["_id"].to_s + " with fullname: " + username
		settings.db.collection("Remakes").update({_id: remake["_id"]}, {"$set" => {user_fullname: username}})
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
			updated_user = users.find_one(update_user_id)
			update_user_name_in_remakes(updated_user)
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
			updated_user = users.find_one(update_user_id)
			update_user_name_in_remakes(updated_user)
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

put '/user/push_token' do
	# input
	user_id = BSON::ObjectId.from_string(params[:user_id])
	device_id = params[:device_id]
	#system_name = params[:system_name]
	android_push_token = params[:android_push_token]

	users = settings.db.collection("Users")
	user = users.find_one(user_id)

	# Validating that the user and the device exists

	if !user then
		# returning an error
		logger.warn "Trying to update the push token for a user that doesn't exist with id " + user_id.to_s
		error_hash = { :message => "User with id " + user_id.to_s + " doesn't exist", :error_code => ErrorCodes::InvalidUserID }
		return [404, [error_hash.to_json]]
	end

	device_found = false
	for device in user["devices"] do
		if device["device_id"] then
			device_found = true if device["device_id"] == device_id
		end
	end

	if !device_found then
		# returning an error
		logger.warn "Trying to update the push token for a device that doesn't exist. user_id=" + user_id.to_s + "; device_id=" + device_id
		error_hash = { :message => "Device with id " + device_id.to_s + " doesn't exist", :error_code => ErrorCodes::InvalidDeviceID }
		return [404, [error_hash.to_json]]		
	end

	# Updating the push token
	users.update({_id: user_id, "devices.device_id" => device_id}, {"$set" => {"devices.$.android_push_token" => android_push_token}})

	return users.find_one(_id: user_id).to_json
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
	user = settings.db.collection("Users").find_one(user_id)
	remake_id = BSON::ObjectId.new
	
	logger.info "Creating a new remake for story <" + story["name"] + "> for user <" + user_id.to_s + "> with remake_id <" + remake_id.to_s + ">"

	s3_folder = "Remakes" + "/" + remake_id.to_s + "/"
	s3_video = s3_folder + story["name"] + "_" + remake_id.to_s + ".mp4"
	s3_thumbnail = s3_folder + story["name"] + "_" + remake_id.to_s + ".jpg"

	remake = {_id: remake_id, story_id: story_id, user_id: user_id, created_at: Time.now ,status: RemakeStatus::New, 
		thumbnail: story["thumbnail"], video_s3_key: s3_video, thumbnail_s3_key: s3_thumbnail}
	# adding the user name if exists
	username = user_name(user)
	remake["user_fullname"] = username if username

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

	# initializing shares, likes, and views counters
	remake[:share_count] = 0
	remake[:like_count] = 0
	remake[:views] = 0

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
	current_user = BSON::ObjectId.from_string(params[:user_id]) if params[:user_id]
	current_cookie = BSON::ObjectId.from_string(params[:cookie_id]) if params[:cookie_id]

	entity_id = ""
	if !current_cookie && !current_user then
		logger.error "no user identity received from client"
	else 
		entity_id = current_user ? current_user : current_cookie
	end


	logger.info "Getting remake with id " + remake_id.to_s

	# Fetching the remake
	remakes = settings.db.collection("Remakes")
	remake = remakes.find_one(remake_id)
	story_id = remake["story_id"]
	story = settings.db.collection("Stories").find_one(story_id)
	remake["share_message"] = story["share_message"] if story["share_message"]
	remake["is_liked"] = userLikedRemake(entity_id,remake_id)

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

def userLikedRemake(entity_id,remake_id)
	current_user_likes = settings.db.collection("Likes").find({
		"$or" => [{remake_id:remake_id, user_id: entity_id},
				  {remake_id:remake_id, cookie_id: entity_id}]
		}).count

	if current_user_likes != 0 then
		return true
	else 
		return false
	end
end


# Returns all the public remakes of a given story
get '/remakes/story/:story_id' do
	# input
	story_id = BSON::ObjectId.from_string(params[:story_id])
	skip = params[:skip].to_i if params[:skip] # Optional
	params[:limit] ? limit = params[:limit].to_i : limit = 80 # Limit is optional, if not passed 80 remakes is the detault limit
	current_user = BSON::ObjectId.from_string(params[:user_id]) if params[:user_id]
	current_cookie = BSON::ObjectId.from_string(params[:cookie_id]) if params[:cookie_id]

	logger.debug "limit is: " + limit.to_s

	entity_id = ""
	if !current_cookie && !current_user then
		logger.error "no user identity received from client"
	else 
		entity_id = current_user ? current_user : current_cookie
	end


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
	remakes_docs = settings.db.collection("Remakes").find({story_id:{"$in" => story_ids}, status: RemakeStatus::Done, user_id:{"$in" => public_users}, grade:{"$ne" => -1}}).sort(grade:-1);
	remakes_docs = remakes_docs.skip(skip) if skip
	remakes_docs = remakes_docs.limit(limit) if limit

	remakes_json_array = Array.new
	for remake_doc in remakes_docs do
		remake_id = remake_doc["_id"]
		remake_doc["is_liked"] = userLikedRemake(entity_id,remake_id)		
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

	logger.info "Footage " + scene_id.to_s + " of Remake " + remake_id.to_s + " with take id " + take_id + " uploaded and now will be processed"

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
	remake = remakes.find_one(remake_id)

	if is_latest_take(remake, scene_id, take_id) then
		# Updating the status of this footage to uploaded
		result = remakes.update({_id: remake_id, "footages.scene_id" => scene_id}, {"$set" => {"footages.$.status" => FootageStatus::Uploaded}})

		logger.info "Footage status updated to Uploaded (1) for remake <" + remake_id.to_s + ">, footage <" + scene_id.to_s + ">"

		# Sending a message to process the new footage
		message = {remake_id: remake_id.to_s, scene_id: scene_id.to_s, take_id: take_id}
		settings.process_footage_queue.send_message(message.to_json)
	else
		# if this is not the latest take, ignoring the call
		logger.info "Ignoring the request since this is not the latest take for remake <" + remake_id.to_s + ">, footage <" + scene_id.to_s + ">"
	end
end

def is_latest_take(remake, scene_id, take_id)
	db_take_id = remake["footages"][scene_id - 1]["take_id"]
	if db_take_id then
		if db_take_id == take_id then
			return true
		else
			logger.info "Not the latest take for remake <" + remake_id.to_s + ">, footage <" + scene_id.to_s + ">. DB take_id <" + db_take_id + "> while given take_id <" + take_id + ">"
			return false
		end
	else
		# No take_id then assuiming this is the latest one
		return true
	end
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
	APN_NEW.push(notification)	
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

# get '/download/:filename' do
# 	downloadPath = settings.outputFolder + params[:filename]
# 	puts "download file path: #{downloadPath}"
# 	send_file downloadPath #, :type => 'video/mp4', :disposition => 'inline'
# end



post '/update/grade' do
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	grade = params[:grade].to_i

	logger.info "updating grade for remake " + remake_id.to_s + " to grade " + grade.to_s

	remakes = settings.db.collection("Remakes")
	remakes.update({_id: remake_id}, {"$set" => {grade: grade}})

	redirect back
end

def getConfigDictionary()
	config = Hash.new 
	config["share_link_prefix"] = settings.share_link_prefix;
	config["significant_view_pct_threshold"] = 0.5
	config["mirror_selfie_silhouette"] = true
	return config
end

#config routes
get '/config' do
	logger.info "recieved additional config request from client"
	config = getConfigDictionary();
	return config.to_json
end

#analytics routes
post '/remake/share' do
	share_id = BSON::ObjectId.from_string(params[:share_id]) if params[:share_id]

	# backword competability fix. 
	if !share_id then
		share_id = BSON::ObjectId.new
	end

	remake_id = BSON::ObjectId.from_string(params[:remake_id]) 
	user_id   =  BSON::ObjectId.from_string(params[:user_id]) if params[:user_id]
	share_method = params[:share_method].to_i if params[:share_method]
	origin_id  = params[:origin_id].to_s if params[:origin_id]
	share_link = params[:share_link].to_s if params[:share_link]
	share_status = params[:share_status] if params[:share_status] 

	#if share link is not shared from client (old clients)
	if !share_link then
		remake = settings.db.collection("Remakes").find_one(remake_id)
		share_link = remake["share_link"]
	end

	logger.info "creating share entity for Remake " + remake_id.to_s + " for user " + user_id.to_s

	shares = settings.db.collection("Shares")
	share = {_id: share_id, remake_id:remake_id, created_at:Time.now}
	share["user_id"] = user_id if user_id
	share["origin_id"] = origin_id if origin_id
	share["share_method"] = share_method if share_method
	share["share_link"] = share_link if share_link
	share["share_status"] = share_status if share_status

	share_objectId = shares.save(share)

	#inc remake like counter
	remakes = settings.db.collection("Remakes")
	remake = remakes.find_one(remake_id)
	remakes.update({_id: remake_id},{"$inc" => {share_count: 1}})

	logger.info "New share saved in the DB with share id " + share_objectId.to_s
	return share.to_json
end

put '/remake/share' do
	share_id  = BSON::ObjectId.from_string(params[:share_id])
	success   = params[:success]
	share_method = params[:share_method].to_i if params[:share_method]

	shares = settings.db.collection("Shares")
	set_dict = {share_status: success}
	set_dict["share_method"] = share_method if share_method

	shares.update({_id: share_id},{"$set" => set_dict})
end

post '/campaign_site/share' do
	info = Hash.new
	info["share_method"] = params[:share_method].to_i if params[:share_method]
	info["campaign_id"] = params[:campaign_id] if params[:campaign_id]
	settings.mixpanel.track("12345", "campaign_site_share", info) if settings.respond_to?(:mixpanel)
end

#social routes
post '/remake/like' do
	#like_id   = BSON::ObjectId.from_string(params[:like_id])
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	user_id   = BSON::ObjectId.from_string(params[:user_id]) if params[:user_id]
	cookie_id = BSON::ObjectId.from_string(params[:cookie_id]) if params[:cookie_id]
	if !user_id && !cookie_id then
		logger.warn "no cookie id nor user id were provided from client. will not record like"
		return nil
	end
	
	#add like
	likes = settings.db.collection("Likes")
	like_info = {remake_id: remake_id}
	like_info["user_id"]   = user_id if user_id
	like_info["cookie_id"] = cookie_id if cookie_id 

	like  = likes.find_one(like_info)
	if like then 
		like_id = like["_id"]
		likes.update({_id: like_id},{"$set" => {like_state: true}})
	else 
		like_info["created_at"] = Time.now
		like_info["like_state"] = true
		like_objectId = likes.save(like_info)
	end

	#inc remake like counter
	remakes = settings.db.collection("Remakes")
	remake = remakes.find_one(remake_id)
	remakes.update({_id: remake_id},{"$inc" => {like_count: 1}})
	
	logger.info "New like saved in the DB with like id " + like_objectId.to_s
	remake = remakes.find_one(remake_id)
	return remake.to_json
end

post '/remake/unlike' do
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	user_id   = BSON::ObjectId.from_string(params[:user_id]) if params[:user_id]
	cookie_id = BSON::ObjectId.from_string(params[:cookie_id]) if params[:cookie_id]
	if !user_id && !cookie_id then
		logger.warn "no cookie id nor user id were provided from client. will not record like"
		return nil
	end

	likes = settings.db.collection("Likes")
	like_info = {remake_id: remake_id}
	like_info["user_id"] = user_id if user_id
	like_info["cookie_id"] = cookie_id if cookie_id
	like  = likes.find_one(like_info)
	
	if !like then 
		logger.warn "no matching previous like. why was unlike called?"
		return nil
	end

	like_id = like["_id"]
	likes.update({_id: like_id},{"$set" => {like_state: false}})
	
	remakes = settings.db.collection("Remakes")
	remake = remakes.find_one(remake_id)
	remakes.update({_id: remake_id},{"$inc" => {like_count: -1}})	

	remake = remakes.find_one(remake_id)
	return remake.to_json
end
	

def getViewSource(user_os, userAgentStr,originating_screen)
	if (user_os =~ /ios/i && userAgentStr =~ /homage/i) then
		return ViewSource::IPhoneApp
	elsif (user_os =~ /android/i && userAgentStr =~ /homage/i) then
		return ViewSource::AndroidApp
	elsif (user_os =~ /mac/i || user_os =~ /windows/i)
		return ViewSource::Desktop
	elsif ((user_os =~ /ios/i || user_os =~ /android/i) && !(userAgentStr =~ /homage/i))
		return ViewSource::Mobile
	elsif (originating_screen == 11) then
		return ViewSource::Desktop
	else
		return ViewSource::Unknown
	end
end

def isImpressionUniqueFromUser(entity_type,entity_id,user_id,cookie_id)
   	impressions = settings.db.collection("Impressions")

   	condition = Hash.new
   	if user_id != nil then 
   		condition["user_id"] = user_id
   	elsif cookie_id != nil then
   		condition["cookie_id"] = cookie_id
   	else
   		logger.info "no cookie nor user id. assuming unique impression"
   		return true
   	end

   	if entity_type == "remake" then
   		condition["remake_id"] = entity_id
   	elsif entity_type == "story" then
   		condition["story_id"] = entity_id
   		condition["remake_id"] = {"$exists" => false}
   	end

   	logger.debug "condition: " + condition.to_s
   	
	res = impressions.find(condition).count
	if (res != 0) then
	   	logger.debug "not unique impression"
	   	return false
	end

	logger.info "unique impression"
	return true
end

def isViewUniqueFromUser(entity_type,entity_id,user_id,cookie_id)
  	views = settings.db.collection("Views")

  	condition = Hash.new
   	if user_id != nil then 
   		condition["user_id"] = user_id
   	elsif cookie_id != nil then
   		condition["cookie_id"] = cookie_id
   	else
   		logger.info "no cookie nor user id. assuming unique view"
   		return true
   	end

   	if entity_type == "remake" then
   		condition["remake_id"] = entity_id
   	elsif entity_type == "story" then
   		condition["story_id"] = entity_id
   		condition["remake_id"] = {"$exists" => false}
   	end

   	logger.debug "condition: " + condition.to_s
   	
	res = views.find(condition).count
	if (res != 0) then
	   	logger.debug "not unique view"
	   	return false
	end

   	logger.debug "unique view"
   	return true
end

def isSignificantViewUnique(entity_type,entity_id,user_id,cookie_id,min_time) 
	views = settings.db.collection("Views")

	condition = Hash.new
	condition["playback_duration"] = {"$gte" => min_time}
   	if user_id != nil then 
   		condition["user_id"] = user_id
   	elsif cookie_id != nil then
   		condition["cookie_id"] = cookie_id
   	else 
   		logger.info "no cookie nor user id. assuming unique significant view"
   		return true
   	end

   	if entity_type == "remake" then
   		condition["remake_id"] = entity_id
   	elsif entity_type == "story" then
   		condition["story_id"] = entity_id
   		condition["remake_id"] = {"$exists" => false}
   	end

	logger.debug "condition: " + condition.to_s
   	
	res = views.find(condition).count
	if (res != 0) then
	   	logger.debug "not unique significant view"
	   	return false
	end

   	logger.debug "unique significant view"
   	return true
end

post '/remake/impression' do
	impressions = settings.db.collection("Impressions")
	remakes = settings.db.collection("Remakes")

	# user agent
	userAgentStr = request.env["HTTP_USER_AGENT"].to_s
	user_agent = UserAgentParser.parse(userAgentStr)
	user_os = user_agent.os.to_s
	logger.debug "user_os=" + user_os.to_s

	client_generated_impression_id = BSON::ObjectId.from_string(params[:impression_id])
	remake_id = BSON::ObjectId.from_string(params[:remake_id])
	user_id =  BSON::ObjectId.from_string(params[:user_id]) if params[:user_id]
	cookie_id = BSON::ObjectId.from_string(params[:cookie_id]) if params[:cookie_id]
	orig_screen = params[:originating_screen].to_i
	origin_id  = params[:origin_id].to_s if params[:origin_id]
	view_source = getViewSource(user_os, userAgentStr, orig_screen)

	remake = remakes.find_one(remake_id)
	story_id = remake["story_id"];

	remakes.update({_id:remake_id},{"$inc" => {web_impressions: 1}})
	if (isImpressionUniqueFromUser("remake",remake_id,user_id,cookie_id)) then
		remakes.update({_id:remake_id},{"$inc" => {unique_web_impressions: 1}})
	end

	impression = {_id:client_generated_impression_id, remake_id:remake_id, story_id: story_id, start_time:Time.now, originating_screen:orig_screen, view_source: view_source}

	impression["user_id"] = user_id if user_id
	impression["cookie_id"] = cookie_id if cookie_id
	impression["origin_id"] = origin_id if origin_id

	logger.info "reporting impression: " + impression.to_s
	impressions.save(impression)

	return impression.to_json
end

def trackView(entity_type,params, user_os, userAgentStr)
	config = getConfigDictionary();
	playback_event = params[:playback_event].to_i
	views = settings.db.collection("Views")

	view = Hash.new
	view["_id"]       = BSON::ObjectId.from_string(params[:view_id])
	view["remake_id"] = BSON::ObjectId.from_string(params[:remake_id]) if params[:remake_id]
	view["story_id"]  = BSON::ObjectId.from_string(params[:story_id]) if params[:story_id]
	view["campaign_id"] = BSON::ObjectId.from_string(params[:campaign_id]) if params[:campaign_id]
	view["user_id"]   = BSON::ObjectId.from_string(params[:user_id]) if params[:user_id]
	view["cookie_id"] = BSON::ObjectId.from_string(params[:cookie_id]) if params[:cookie_id]
	
	#start related props
	view["originating_screen"] = params[:originating_screen].to_i
	view["origin_id"]          = params[:origin_id].to_s if params[:origin_id]
	view["view_source"]        = getViewSource(user_os, userAgentStr,view["originating_screen"])

	# end/update related props
	view["playback_duration"] = params[:playback_duration].to_f if params[:playback_duration]
	view["total_duration"] = params[:total_duration].to_f if params[:total_duration]

	collection = ""
	entity_id = ""
	if entity_type == "remake" then
		collection = settings.db.collection("Remakes")
		remake_id = view["remake_id"]
		remake = collection.find_one(remake_id)
		view["story_id"] = remake["story_id"]
		entity_id = view["remake_id"]
	elsif entity_type == "story" then
		collection = settings.db.collection("Stories")
		entity_id  = view["story_id"]
	elsif entity_type == "campaign_video" then
		collection = settings.db.collection("Campaigns")
		entity_id = view["campaign_id"]
	end

	if playback_event == PlaybackEventType::PlaybackEventStart then
		view["start_time"] = Time.now
		collection.update({_id:entity_id},{"$inc" => {views: 1}})
		user_id = view["user_id"]
		cookie_id = view["cookie_id"]
		if (isViewUniqueFromUser(entity_type,entity_id,user_id,cookie_id)) then
			collection.update({_id:entity_id},{"$inc" => {unique_views: 1}})
		end

		logger.info "reporting view start: " + view.to_s
		view_objectId = views.save(view)
		logger.info "New view saved in the DB with view id " + view_objectId.to_s
		
		return view.to_json

	elsif playback_event = PlaybackEventType::PlaybackEventStop then
		view_id           = view["_id"]
		playback_duration = view["playback_duration"]
		total_duration    = view["total_duration"]
		user_id           = view["user_id"] 
		cookie_id         = view["cookie_id"]
		
		existing_view = views.find_one(view_id)
		if !existing_view then
			logger.error "No matching start event for stop event: " + view_id.to_s
		end
		
		th = config["significant_view_pct_threshold"]
		min_time = total_duration * th

		logger.debug "playback_duration:" + playback_duration.to_s
		logger.debug "min_time: " + min_time.to_s

		if (playback_duration > min_time) then 
			if !existing_view["playback_duration"]
				logger.debug "incrementing significant_views"
				collection.update({_id:entity_id},{"$inc" => {significant_views: 1}})
			end

			if (isSignificantViewUnique(entity_type,entity_id,user_id,cookie_id,min_time)) then
				logger.debug "incrementing unique significant_views"
				collection.update({_id:entity_id},{"$inc" => {unique_significant_views: 1}})
			end
		end

		view_params = {playback_duration: playback_duration, total_duration: total_duration}
		views.update({_id: view_id},{"$set" => view_params})
		logger.info "view updated in the DB with view id " + view_id.to_s + "and view duration: " + playback_duration.to_s
		view = views.find_one(view_id)
		return view.to_json
	end
end


post '/remake/view' do 
	# user agent
	userAgentStr = request.env["HTTP_USER_AGENT"].to_s
	user_agent = UserAgentParser.parse(userAgentStr)
	user_os = user_agent.os.to_s

	trackView("remake",params, user_os, userAgentStr)
end

post '/story/view' do 
	# user agent
	userAgentStr = request.env["HTTP_USER_AGENT"].to_s
	user_agent = UserAgentParser.parse(userAgentStr)
	user_os = user_agent.os.to_s

	trackView("story",params, user_os, userAgentStr)
end

post '/campaign_video/view' do 
	# user agent
	userAgentStr = request.env["HTTP_USER_AGENT"].to_s
	user_agent = UserAgentParser.parse(userAgentStr)
	user_os = user_agent.os.to_s

	trackView("campaign_video",params, user_os, userAgentStr)
end


post '/user/session_begin' do
	client_generated_session_id = BSON::ObjectId.from_string(params[:session_id])
	user_id =  BSON::ObjectId.from_string(params[:user_id])

	sessions = settings.db.collection("Sessions")

	user_session = {_id:client_generated_session_id, user_id:user_id, start_time:Time.now}
	user_session_objectId = sessions.save(user_session)
		
	logger.info "New user session saved in the DB with view id" + user_session_objectId.to_s
	return user_session.to_json
end

post '/user/session_update' do
	user_session_id = BSON::ObjectId.from_string(params[:session_id])
	new_user_id =  BSON::ObjectId.from_string(params[:user_id])

	sessions = settings.db.collection("Sessions")
	user_session = sessions.find_one(user_session_id)
	if !user_session then
		logger.info "No matching start event for stop event: " + user_session_id.to_s
	end

	sessions.update({_id: user_session_id},{"$set" => {user_id: new_user_id}})
	logger.info "user session updated with session id " + user_session_id.to_s
	user_session = sessions.find_one(user_session_id)
	return user_session.to_json
end

post '/user/session_end' do
	user_session_id = BSON::ObjectId.from_string(params[:session_id])
	user_id =  BSON::ObjectId.from_string(params[:user_id])

	sessions = settings.db.collection("Sessions")
	user_session = sessions.find_one(user_session_id)
	if !user_session then
		logger.info "No matching start event for stop event: " + user_session_id.to_s
		return nil
	end
	start_time = user_session["start_time"]
	if user_session["duration_in_minutes"] then
		logger.warn "user session with session id: " + user_session_id.to_s + " had already finished once. this is bad. ignoring the second finish event"
		return nil
	else
		end_time = Time.now
		duration_in_seconds = end_time - start_time

		#ignoring glitch sessions (short false sessions)
		if duration_in_seconds < 30 then 
			logger.info "user session shorter then 30 seconds. deleting"
			sessions.remove({_id: user_session_id});
			return nil
		end

		duration_in_minutes = duration_in_seconds.to_f/60
		sessions.update({_id: user_session_id},{"$set" => {duration_in_minutes: duration_in_minutes.round(2)}})
		logger.info "user session finished with session id " + user_session_id.to_s
		user_session = sessions.find_one(user_session_id)
	end
	return user_session.to_json
end


get '/analytics' do

	Analytics.init_db(settings.db)

	_start_date = Time.parse(params[:start_date])
	_end_date   = Time.parse(params[:end_date])
	stories_array = params[:stories];

	bson_story_array = Array.new
    stories_array.each { |story_id| bson_story_array.push(BSON::ObjectId.from_string(story_id)) }  

	start_date =  Time.parse(_start_date.strftime("%Y%m%dZ"))
	end_date   =  Time.parse(_end_date.strftime("%Y%m%dZ"))

	logger.info "analytics period: start_date " + start_date.iso8601 + " end date: " + end_date.iso8601

	launch_date = Time.parse("20140430Z")
	Analytics.init_db(settings.db)

	######
	@heading1 = "% of shared videos out of all created movies "
	@data1    = Analytics.get_pct_of_shared_videos_for_date_range_out_of_all_created_movies(start_date,end_date,bson_story_array)
	@value_format1 = {nominator: "shared video: " , denominator: "Total videos for period:"}
	######
	@heading2 = "% of users that shared at least once out of all active users"
	@data2    = Analytics.get_pct_of_users_who_shared_at_list_once_for_date_range(start_date,end_date,bson_story_array) 
	@value_format2 = {nominator: "Sharing users: " , denominator: "Total users for period:"}
    #####
	#@heading3 = "distribution of movie making between users from date: " + launch_date.iso8601
	#@data3    = Analytics.get_distribution_of_remakes_between_users_from_date(launch_date)
	#####
	@heading4 = "views for story" 
	@data4 = Analytics.get_total_views_for_story_for_date_range(start_date,end_date,bson_story_array)
	
	######
	@heading5 = "avg session time between dates"
	@data5 = Analytics.get_avg_session_time_for_date_range(start_date,end_date)
	######
	@heading6 = "remake distibution between users by count from start_date" + start_date.iso8601
	@data6 =  Analytics.get_user_distibution_per_number_of_remakes(start_date,end_date,3)
	######
	@heading7 = "% of failed remakes"
	@data7 = Analytics.get_pct_of_failed_remakes_for_date_range(start_date,end_date,bson_story_array)
	@value_format7 = {nominator: "Failed remakes: " , denominator: "Total remakes for day: "}

	return [["line" , KPIGraphType::NormalFractionGraphType, @heading1, @data1, @value_format1],
	 		["line", KPIGraphType::NormalFractionGraphType, @heading2, @data2, @value_format2],
	 		["stacked grouped bars" , KPIGraphType::StoryViewsGraphType, @heading4,  @data4],
	 		["line" , KPIGraphType::AvgValueGraphType, @heading5, @data5],
	 		["pie", KPIGraphType::PieChartGraphType ,@heading6, @data6],
	 		["line", KPIGraphType::NormalFractionGraphType ,@heading7, @data7, @value_format7]].to_json
end


get '/dashboard' do
	erb :analytics_dashboard
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

get '/test/mail' do
	Mail.deliver do
	  from     'homage-server-app@homage.it'
	  to       'nir@homage.it'
	  subject  'Test Mail'
	  body     'Test body...'
	end

	"Mail sent successfully"
end

get '/test/minisite' do
	erb :HMGMiniSite
end

get '/test/:entity_id' do
		remakes = settings.db.collection("Remakes")
		users   = settings.db.collection("Users")
		shares  = settings.db.collection("Shares")
		stories = settings.db.collection("Stories")
		@config = getConfigDictionary();
		
		entity_id = BSON::ObjectId.from_string(params[:entity_id])
		@share  = shares.find_one(entity_id)
		if @share == nil then
			@remake = remakes.find_one(entity_id)
			@originating_share_id = ""
		else 
			remake_id = @share["remake_id"]
			@remake = remakes.find_one(remake_id)
			@originating_share_id = @share["_id"]
			shares.update({_id: @originating_share_id},{"$set" => {share_status: true}})
		end

		
		if BSON::ObjectId.legal?(@remake["user_id"]) then
			@user = users.find_one(@remake["user_id"])
		else
			@user = users.find_one({_id: @remake["user_id"]})
		end

		
		@story = stories.find_one(@remake["story_id"])

		erb :HMGVideoPlayer
end

def download_remake_from_s3(remake_id_str, download_folder)

	remakes = settings.db.collection("Remakes")
	stories = settings.db.collection("Stories")

	remake_id = BSON::ObjectId.from_string(remake_id_str)

	# Getting the remake
	remake = remakes.find_one(remake_id)
	if !remake then
		logger.info "Remake not found!"
		return
	end
	story = stories.find_one(remake["story_id"])

	s3 = AWS::S3.new
	bucket = s3.buckets['homageapp']
	# Getting all the remake's file from S3
	remake_s3_prefix = "Remakes/" + remake["_id"].to_s
	remake_s3_objects = bucket.objects.with_prefix(remake_s3_prefix)
	files = []
	for remake_s3_object in remake_s3_objects do
		# Saving each file to the download folder
		basename = remake_id.to_s + "_" + File.basename(remake_s3_object.key, ".*")
		extension = File.extname(remake_s3_object.key)
		if(extension == '.zip')
			return remake_s3_object
		end
		download_to_path = download_folder + basename + extension

		logger.info "Downloading file " + File.basename(remake_s3_object.key) + "..."

		download_from_s3(remake_s3_object, download_to_path)
		files.push basename + extension

		if remake_s3_object.key.include? "raw_scene" then
			scene_id = basename[-1,1].to_i # The last char is the scene_id
			contour_orig_url = story["scenes"][scene_id - 1]["contours"]["360"]["contour_remote"]
			contour_face_url = File.dirname(contour_orig_url) + "/Face/" + File.basename(contour_orig_url,".*") + "-face.ctr"

			extension = ".ctr"
			download_to_path = download_folder + basename + extension

			logger.info "Downloading file " + File.basename(contour_face_url) + "..."
			open(download_to_path, 'wb') do |file|
				file << open(contour_face_url).read
			end
			files.push basename + extension
		end
	end

	return files
end

def zipfolder(download_folder, input_filenames, remake_id)
	zipfile_name = download_folder + remake_id.to_s + '.zip'

		Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
		  	input_filenames.each do |filename|
			    # Two arguments:
			    # - The name of the file as it will appear in the archive
			    # - The original file, including the path to find it
			    logger.info 'zipping file' + filename
				zipfile.add(filename, download_folder + '/' + filename)
			  end
			  #zipfile.get_output_stream("myFile") { |os| os.write "myFile contains just this" }
			  logger.info 'finished zip'
		end
		logger.info remake_id.to_s + '.zip'
		return remake_id.to_s + '.zip'
end

def upload_to_s3 (file_path, s3_key, acl, content_type=nil)
	s3 = AWS::S3.new
	bucket = s3.buckets['homageapp']
	s3_object = bucket.objects[s3_key]

	logger.info 'Uploading the file <' + file_path + '> to S3 path <' + s3_object.key + '>'
	#file = File.new(file_path)
	s3_object.write(Pathname.new(file_path), {:acl => acl, :content_type => content_type})
	#file.close
	logger.info "Uploaded successfully to S3, url is: " + s3_object.public_url.to_s

	return s3_object
end

def download_from_s3 (s3_object, local_path)

	logger.info "Downloading file from S3 with key " + s3_object.to_s
	
	File.open(local_path, 'wb') do |file|
  		s3_object.read do |chunk|
    		file.write(chunk)
    	end
    end

  	logger.info "File downloaded successfully to: " + local_path
end


get '/download/remake/:remake_id' do
	remake_id = params[:remake_id]

	download_folder = "/download_folder/" + remake_id.to_s + "/"
	# Creating the download folder
	FileUtils.mkdir_p download_folder

	logger.info 'Start Download'
	input_filenames = download_remake_from_s3(remake_id.to_s, download_folder)
	s3_object = nil
	#Was there a zip file or was it an array of strings?
	if(input_filenames.instance_of? Array)
	
			#rubyzip
			logger.info 'Start Zip'
			zipfile_name = zipfolder(download_folder, input_filenames, remake_id)
			logger.info 'Zipfile name: ' + zipfile_name

			#upload zip to s3
			logger.info 'Upload to S3' 
			s3_key = 'Remakes/' + remake_id.to_s + '/' + zipfile_name
			file_path = download_folder + zipfile_name
			s3_object = upload_to_s3(file_path, s3_key, :public_read, 'application/zip')
	else
			s3_object = input_filenames
	end

	#delete all files from server
	logger.info 'Remove Folder' 
	FileUtils.rm_rf(download_folder)
	#return  s3 link
	return s3_object.public_url.to_s
end
