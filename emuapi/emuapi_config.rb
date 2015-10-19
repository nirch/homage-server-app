#encoding: utf-8
require 'mongo_mapper'
require 'maxminddb'
require_relative '../utils/aws/aws_manager'
#
# Emu test configurations
#
configure :test do
  emu_db_connection_scratchpad = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10009/emu-dev-test")
  emu_db_connection_public = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10008/emu-dev-prod")
  # emu_db_connection_test = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10073/emu-test")

  # set :emu_test, emu_db_connection_test
  set :emu_scratchpad, emu_db_connection_scratchpad
  set :emu_public, emu_db_connection_public

  MongoMapper.connection = emu_db_connection_public
  MongoMapper.database = emu_db_connection_public.db().name

  set :emu_s3_test, AWSManager::S3Manager.emu_dev_test
  set :emu_s3_prod, AWSManager::S3Manager.emu_dev_prod

  set :emumixpanel_token, "090553b00ef0bbe21ba634c651dc272f"
  set :emumixpanel, Mixpanel::Tracker.new(settings.emumixpanel_token)

  set :enviornment, "test"

  set :logging, Logger::DEBUG

  # geo location data
  set :geodb, MaxMindDB.new('geoip/GeoLite2-Country.mmdb')

end

#
# Emu production configurations
#
configure :production do
  emu_db_connection_scratchpad = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10073/emu-test")
  emu_db_connection_public = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10005/emu-prod")

  set :emu_scratchpad, emu_db_connection_scratchpad
  set :emu_public, emu_db_connection_public

  MongoMapper.connection = emu_db_connection_public
  MongoMapper.database = emu_db_connection_public.db().name

  set :emu_s3_test, AWSManager::S3Manager.emu_test
  set :emu_s3_prod, AWSManager::S3Manager.emu_prod

  set :emumixpanel_token, "25847b0e1fc41bc665d204be1a2c96ee"
  set :emumixpanel, Mixpanel::Tracker.new(settings.emumixpanel_token)

  set :enviornment, "production"

  set :logging, Logger::INFO

  # geo location data
  set :geodb, MaxMindDB.new('geoip/GeoLite2-Country.mmdb')

end

def scratchppad_or_produdction_connection(request)
  #
  # determine connection required (public/scratchpad)
  #
  connection = settings.emu_public
  use_scratchpad = request.env['HTTP_SCRATCHPAD'].to_s  
  if use_scratchpad == "true" then connection = settings.emu_scratchpad end
  return connection
end