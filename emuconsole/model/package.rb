class Package
  include MongoMapper::Document
  	key :first_published_on, Date
    key :created_at, Date
  	key :last_update, Date
  	key :icon_name, String
  	key :name, String
  	key :label, String
  	key :active, Boolean, :default => true
  	key :dev_only, Boolean, :default => false
  	key :emuticons_defaults, Hash
  	many :emuticons
end