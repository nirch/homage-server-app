class Emuticon
  include MongoMapper::EmbeddedDocument
	key :name, String
	key :source_back_layer,      String
	key :source_front_layer, String
	key :source_user_layer_mask, String
	key :duration, Integer
	key :frames_count, Integer
	key :thumbnail_frame_index, Integer
	key :palette, String
	key :patched_on, Time
	key :tags, String
	key :use_for_preview, Boolean
end