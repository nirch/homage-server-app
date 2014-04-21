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

stories_to_copy = Set.new [dive_school_id, aliens_id, monster_attack_id, oscar_id]

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
