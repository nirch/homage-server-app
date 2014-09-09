require 'mongo'


prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db

prod_stories = prod_db.collection("Stories")
prod_remakes = prod_db.collection("Remakes")
test_stories = test_db.collection("Stories")

# Stories
dive_school_id = BSON::ObjectId.from_string("530dd1e5784380a058000601")
aliens_id = BSON::ObjectId.from_string("53206e5514b2ecc477000241")
monster_attack_id = BSON::ObjectId.from_string("532f058a3f13af9af80001bb")
oscar_id = BSON::ObjectId.from_string("534fc5b9924daff68b0000e9")
dumb_n_helpless_id = BSON::ObjectId.from_string("53565aa49c5200617200017a")
turbo_ski_id = BSON::ObjectId.from_string("5356dc94ebad7c3bf100015d")
superior_man_id = BSON::ObjectId.from_string("535e8fc981360cd22f0003d4")
the_interpreter_id = BSON::ObjectId.from_string("535704b5c133e52ecb00016d")
world_cup_brazil_id = BSON::ObjectId.from_string("53b540d3123459d5aa000253")
world_cup_argentina_id = BSON::ObjectId.from_string("53b17db89a452198f80004a6")
world_cup_coach_id = BSON::ObjectId.from_string("53bffcbbf0c5349d4600058f")
f1_id = BSON::ObjectId.from_string("53c7d110c05d603a910003d6")
street_fighter_id = BSON::ObjectId.from_string("53ce9bc405f0f6e8f2000655")
hello_nyan_kitty_id = BSON::ObjectId.from_string("53ec8c014b7b616933000122")


stories_to_copy = Set.new [
	# dive_school_id, 
	# aliens_id, 
	# monster_attack_id, 
	# oscar_id, 
	# dumb_n_helpless_id, 
	# turbo_ski_id, 
	# superior_man_id, 
	# the_interpreter_id,
    #world_cup_brazil_id,
	#world_cup_argentina_id,
	#world_cup_coach_id,
	#f1_id,
	#street_fighter_id,
	hello_nyan_kitty_id
	]

for story_id in stories_to_copy do
	# Getting the story from test to copy
	story_to_copy = test_stories.find_one({_id: story_id})

	# Updating the story with the num of remakes from production
	story_remakes_in_prod = prod_remakes.count({query: {story_id: story_id, status: 3}})
	story_to_copy["remakes_num"] = story_remakes_in_prod

	# Updating/Creating the story in production
	result = prod_stories.update({_id: story_id}, story_to_copy, {upsert: true})
	puts story_to_copy["name"] + " copy to prod result = " + result.to_s
end
