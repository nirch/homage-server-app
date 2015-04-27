class Package
  include MongoMapper::Document
  	key :first_published_on, Time
    key :notification_text, String
  	key :last_update, Time
    key :meta_data_created_on, Time
    key :meta_data_last_update, Time
    key :cms_first_published, Time
    key :cms_last_published, Time
  	key :icon_name, String
    key :cms_icon_2x, String
    key :cms_icon_3x, String
    key :zipped_package_file_name, String
    key :cms_state, String
    key :cms_proccessing, Boolean, :default => false
  	key :name, String
  	key :label, String
  	key :active, Boolean, :default => true
  	key :dev_only, Boolean, :default => false
  	key :emuticons_defaults, Hash
  	many :emuticons
end