require 'mongo'

test_db = Mongo::MongoClient.from_uri("mongodb://Homage:homageIt12@paulo.mongohq.com:10008/Homage").db
users = test_db.collection("Users")
remakes = test_db.collection("Remakes")
stories = test_db.collection("Stories")

# ************ Change the user_id here *****************************
user_id = BSON::ObjectId.from_string("5333eeb6f52d5c3ae5000004")
user = users.find_one(user_id)
	
remake_id = BSON::ObjectId.new

# *********** Change the story_id to get different stories (thumbnails)
 story_id = BSON::ObjectId.from_string("52de83db8bc427751c000305") # Dive School
# story_id = BSON::ObjectId.from_string("52ee613cab557ec484000021") # The Oscars
# story_id = BSON::ObjectId.from_string("52cddaf80fad07c3290001aa") # Star Wars
# story_id = BSON::ObjectId.from_string("52c18c569f372005e0000286") # Test
# story_id = BSON::ObjectId.from_string("5315c2d2717f5df24a0001a7") # Dive School 2
# story_id = BSON::ObjectId.from_string("52c4341d220b10ce920001a7") # Birthday
# story_id = BSON::ObjectId.from_string("5320cade72ec727673000402") # Hot Topic
# story_id = BSON::ObjectId.from_string("53206e5514b2ecc477000241") # Aliens
# story_id = BSON::ObjectId.from_string("532f058a3f13af9af80001bb") # Monster Attack
story = stories.find_one(story_id)

share_link = "http://play.homage.it/" + remake_id.to_s

remake = {_id: remake_id, story_id: story_id, user_id: user_id, created_at: Time.now ,status: 3, 
		video: story["video"], thumbnail: story["thumbnail"], share_link: share_link }

remake_objectId = remakes.save(remake)

puts remake_objectId

