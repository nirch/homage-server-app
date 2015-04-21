class Emuticon
  include MongoMapper::EmbeddedDocument
	key :name, String
	key :source_back_layer,      String
	key :source_front_layer, String
	key :source_user_layer_mask, String
	key :palette, String
	key :patchedOn, Time
	key :tags, String
	key :use_for_preview, Boolean
end