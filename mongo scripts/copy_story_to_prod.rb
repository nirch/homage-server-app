require 'mongo'


prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db

prod_stories = prod_db.collection("Stories")
prod_remakes = prod_db.collection("Remakes")
test_stories = test_db.collection("Stories")

story_id_string = ARGV[0]
story_id = BSON::ObjectId.from_string(story_id_string)

# Getting the story from test to copy
story_to_copy = test_stories.find_one({_id: story_id})

# Updating the story with the num of remakes from production
story_remakes_in_prod = prod_remakes.count({query: {story_id: story_id, status: 3}})
story_to_copy["remakes_num"] = story_remakes_in_prod

# Updating/Creating the story in production
result = prod_stories.update({_id: story_id}, story_to_copy, {upsert: true})
puts story_to_copy["name"] + " copy to prod result = " + result.to_s
