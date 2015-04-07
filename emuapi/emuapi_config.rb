#encoding: utf-8
require 'mongo_mapper'
require_relative '../utils/aws/aws_manager'
require 'byebug'
#
# Emu test configurations
#
configure :test do
  emu_db_connection_scratchpad = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10009/emu-dev-test")
  emu_db_connection_public = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10008/emu-dev-prod")

  set :emu_scrathpad, emu_db_connection_scratchpad
  set :emu_public, emu_db_connection_public

  MongoMapper.connection = emu_db_connection_public
  MongoMapper.database = emu_db_connection_public.db().name

  set :emu_s3_test, AWSManager::S3Manager.emu_dev_test
  set :emu_s3_prod, AWSManager::S3Manager.emu_dev_prod
end

#
# Emu production configurations
#
configure :production do
  emu_db_connection_scratchpad = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10073/emu-test")
  emu_db_connection_public = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10005/emu-prod")

  set :emu_scrathpad_db, emu_db_connection_scratchpad
  set :emu_public_db, emu_db_connection_public

  MongoMapper.connection = emu_db_connection_public
  MongoMapper.database = emu_db_connection_public.db().name

  set :emu_s3_test, AWSManager::S3Manager.emu_test
  set :emu_s3_prod, AWSManager::S3Manager.emu_prod
end