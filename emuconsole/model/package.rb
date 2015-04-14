class Package
  include MongoMapper::Document
  	key :first_published_on, Date
  	key :last_update, Date
    key :meta_data_created_on, Date
    key :meta_data_last_update, Date
  	key :icon_name, String
    key :cms_icon_2x, String
    key :cms_icon_3x, String
  	key :name, String
  	key :label, String
  	key :active, Boolean, :default => true
  	key :dev_only, Boolean, :default => false
  	key :emuticons_defaults, Hash
  	many :emuticons
end