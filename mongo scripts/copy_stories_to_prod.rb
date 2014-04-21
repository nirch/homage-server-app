require 'mongo'


prod_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@troup.mongohq.com:10057/Homage_Prod").db
test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db

prod_stories = prod_db.collection("Stories")
test_stories = test_db.collection("Stories")

stories_to_copy = Set.new ["530dd1e5784380a058000601", "53206e5514b2ecc477000241", "532f058a3f13af9af80001bb", "534fc5b9924daff68b0000e9"]

for story_id in stories_to_copy do
	story_to_copy = test_stories.find_one({_id: BSON::ObjectId.from_string(story_id)})
	puts story_to_copy["name"]
end
