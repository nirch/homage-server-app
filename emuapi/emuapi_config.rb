#encoding: utf-8
require 'mongo_mapper'
#
# Emu test configurations
#
configure :test do
  emu_db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10073/emu-test")
  set :emu_db, emu_db_connection.db()
  MongoMapper.connection = emu_db_connection
  MongoMapper.database = emu_db_connection.db().name
end

#
# Emu production configurations
#
configure :production do
  emu_db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10005/emu-prod")
  set :emu_db, emu_db_connection.db()
  MongoMapper.connection = emu_db_connection
  MongoMapper.database = emu_db_connection.db().name
end