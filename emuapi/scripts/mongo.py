from pymongo import MongoClient

connection = None
db = None


def init():
	global connection, db
	connection = MongoClient("mongodb://Homage:homageIt12@dogen.mongohq.com:10009/emu-dev-test")
	db = connection['emu-dev-test']

def update_timestamp_fix():
	for pack in db.packages.find():
		print pack


if __name__ == '__main__':
	init()
	update_timestamp_fix()