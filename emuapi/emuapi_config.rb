#encoding: utf-8

#
# Emu test configurations
#
configure :test do
  emu_db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10073/emu-test")
  set :emu_db, emu_db_connection.db()
end

#
# Emu production configurations
#
configure :production do
  emu_db_connection = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@dogen.mongohq.com:10005/emu-prod")
  set :emu_db, emu_db_connection.db()
end