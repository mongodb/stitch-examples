import unittest

from pybaas.client import Error
from pybaas import AdminClient, APIClient, Connection
from pybaas.auth import UserPass
import pybaas.svcs.mongodb as mongodb
from pybaas.auth_provider import AuthProvider
from pybaas.variable import Variable

from bson.objectid import ObjectId

from pymongo import MongoClient

class TestMethods(unittest.TestCase):

	def setUp(self):

		# Clear data
		client = MongoClient()
		client.drop_database('planner')
		self._m_client = client

		creds = UserPass('unique_user@domain.com', 'password')
		self._cl = APIClient(Connection(creds), app='planner')

	def test_boards(self):
		mdb = mongodb.Service(self._cl.service('mdb1'))

		# Create board
		# TODO(erd): This should have a rule to enforce count is >= 0
		boards = mdb.database('planner').collection('boards')
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})

		# Create board twice should fail
		with self.assertRaisesRegexp(Error, 'validation failed'):
			boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})

		# Create board without name should fail
		with self.assertRaisesRegexp(Error, 'name is required'):
			boards.insert({'owner_id': self._cl.user()['_id']})

		# Create board without valid name should fail
		with self.assertRaisesRegexp(Error, 'validation failed'):
			boards.insert({'name': '', 'owner_id': self._cl.user()['_id']})

		# Create board without valid owner_id should fail
		with self.assertRaisesRegexp(Error, 'validation failed'):
			boards.insert({'name': '', 'owner_id': 'myid'})

		# Create some other board
		other_board = ObjectId()
		self._m_client.planner.boards.insert_one({'_id': other_board, 'name': 'Personal', 'owner_id': ObjectId(), 'members': [self._cl.user()['_id']]})

		# Finding own board should work
		personal = boards.find({'owner_id': self._cl.user()['_id'], 'name': 'Personal'})
		self.assertTrue(len(personal) == 1)
		personal = personal[0]
		self.assertTrue(personal['owner_id'] == self._cl.user()['_id'])

		# # Adding a member should fail if username isn't registered
		# # This won't fail. No way to express
		# boards.update(
		# 	{'owner_id': self._cl.user()['_id'], 'name': 'Personal'},
		# 	{'$addToSet': {'members': 'otheruser'}})

		# # Adding a member that is registered should work.
		# # This won't fail. No way to express
		# boards.update(
		# 	{'owner_id': self._cl.user()['_id'], 'name': 'Personal'},
		# 	{'$addToSet': {'members': 'gooduser'}})

		# # Adding the same member twice should not work.
		# # This won't fail. No way to express. Pretty much $addToSet should be enforced
		# boards.update(
		# 	{'owner_id': self._cl.user()['_id'], 'name': 'Personal'},
		# 	{'$push': {'members': 'gooduser'}})

		# Removing a member should work (registered or not)
		boards.update(
			{'owner_id': self._cl.user()['_id'], 'name': 'Personal'},
			{'$pull': {'members': 'gooduser'}})
		boards.update(
			{'owner_id': self._cl.user()['_id'], 'name': 'Personal'},
			{'$pull': {'members': 'otheruser'}})

		# # Modifying members on a board that am member of should fail
		# with self.assertRaisesRegexp(Error, 'is not mutable'):
		# 	boards.update(
		# 		{'_id': other_board},
		# 		{'$addToSet': {'members': 'gooduser'}})

		# Deleting own board should work
		boards.remove({'_id': personal['_id']})
		self.assertTrue(len(boards.find({'owner_id': self._cl.user()['_id'], 'name': 'Personal'})) == 0)

		# Other board should still exist
		other = self._m_client.planner.boards.find_one({'name': 'Personal'})
		self.assertTrue(other['owner_id'] != self._cl.user()['_id'])

	def test_lists(self):
		mdb = mongodb.Service(self._cl.service('mdb1'))

		# With a board
		boards = mdb.database('planner').collection('boards')
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})
		personal_board = boards.find({'name': 'Personal'})[0]

		# Adding a new list should work
		list_id = ObjectId()
		idx_1 = 0
		boards.update({'_id': personal_board['_id']}, 
			{'$set': {'lists.'+str(list_id): {'_id': list_id, 'name': 'todo', 'idx': 0}},
			'$inc': {'lcount': 1}})

		# Adding a new list to someone else's board

		# Create some other boards
		other_board_1 = ObjectId()
		other_board_2 = ObjectId()

		self._m_client.planner.boards.insert_one({'_id': other_board_1, 'name': 'Shared', 'owner_id': ObjectId(), 'members': [self._cl.user()['_id']]})
		self._m_client.planner.boards.insert_one({'_id': other_board_2, 'name': 'Shared', 'owner_id': ObjectId()})

		# Should work when we are a member of the list
		# Expressing this is hard as is since we don't have acceess to the board being used.
		# We can however gather all of the boards that this user is a part of (agg) and verify?
		boards.update({'_id': other_board_1}, 
			{'$set': {'lists.'+str(list_id): {'_id': list_id, 'name': 'todo', 'idx': 0}},
			'$inc': {'lcount': 1}})

		# Should fail when we are not a member of the list
		# with self.assertRaisesRegexp(Error, '(?i)no matching documents found'):
		# 	boards.update({'_id': other_board_2}, 
		# 		{'$set': {'lists.'+str(list_id): {'_id': list_id, 'name': 'todo', 'idx': 0}},
		# 		'$inc': {'lcount': 1}})

		# Adding a new list with a bad name should fail
		# TODO(erd): Needs a rule that can describe this ($regex not supported)

		personal_board = boards.find({'name': 'Personal'})[0]

		# Swapping two lists should work
		other_id = ObjectId()
		idx_2 = 1
		boards.update({'_id': personal_board['_id']}, 
			{'$set': {'lists.'+str(other_id): {'_id': other_id, 'name': 'other', 'idx': 1}},
			'$inc': {'lcount': 1}})
		
		boards.update({
			'_id': personal_board['_id']},
			{'$set': {'lists.'+str(list_id)+'.idx': idx_2, 'lists.'+str(other_id)+'.idx': idx_1}})

		personal_board = boards.find({'name': 'Personal'})[0]
		self.assertTrue(personal_board['lists'][str(list_id)]['idx'] == idx_2)
		self.assertTrue(personal_board['lists'][str(other_id)]['idx'] == idx_1)

		# Removing a list should work
		boards.update({'_id': personal_board['_id']}, {'$unset': {'lists.'+str(list_id): True}, '$inc': {'lcount': -1}})

		updated = boards.find({'name': 'Personal'})[0]
		self.assertTrue(str(other_id) in updated['lists'])
		self.assertFalse(str(list_id) in updated['lists'])
		self.assertTrue(updated['lcount'] == 1)

	def test_cards(self):
		mdb = mongodb.Service(self._cl.service('mdb1'))

		# With a board and list
		boards = mdb.database('planner').collection('boards')
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})
		personal_board = boards.find({'name': 'Personal'})[0]

		# TODO(erd): This should have a rule to enforce count is >= 0
		todo_id = ObjectId()
		boards.update({'_id': personal_board['_id']}, {'$set': {'lists.'+str(todo_id): {'ccount': 0}}})
		personal_board = boards.find({'name': 'Personal'})[0]

		num_cards = personal_board['lists'][str(todo_id)]['ccount']

		# Adding a new card should work
		cards = mdb.database('planner').collection('cards')

		card_id = ObjectId()
		idx_1 = num_cards
		boards.update({
			'_id': personal_board['_id']},
			{'$set': {'lists.'+str(todo_id)+'.cards.'+str(card_id): {"_id": card_id, "text": "hello", "idx": idx_1}},
			'$inc': {'lists.'+str(todo_id)+'.ccount': 1}})
		cards.insert({'_id': card_id, 'author': self._cl.user()['_id'], 'summary': 'hello'})

		personal_board = boards.find({'name': 'Personal'})[0]
		num_cards = personal_board['lists'][str(todo_id)]['ccount']

		other_card_id = ObjectId()
		idx_2 = num_cards
		boards.update({
			'_id': personal_board['_id']},
			{'$set': {'lists.'+str(todo_id)+'.cards.'+str(other_card_id): {"_id": other_card_id, "text": "it's me", "idx": idx_2}},
			'$inc': {'lists.'+str(todo_id)+'.ccount': 1}})
		cards.insert({'_id': other_card_id, 'author': self._cl.user()['_id'], 'summary': "it's me"})

		# Swapping two cards should work
		boards.update({
			'_id': personal_board['_id']},
			{'$set': {'lists.'+str(todo_id)+'.cards.'+str(card_id)+'.idx': idx_2, 'lists.'+str(todo_id)+'.cards.'+str(other_card_id)+'.idx': idx_1}})

		personal_board = boards.find({'name': 'Personal'})[0]
		self.assertTrue(personal_board['lists'][str(todo_id)]['cards'][str(card_id)]['idx'] == idx_2)
		self.assertTrue(personal_board['lists'][str(todo_id)]['cards'][str(other_card_id)]['idx'] == idx_1)

		# Removing a card should work
		boards.update({'_id': personal_board['_id']}, {'$unset': {'lists.'+str(todo_id)+'.cards.'+str(card_id): True}, '$inc': {'lists.'+str(todo_id)+'.ccount': -1}})
		cards.remove({'_id': card_id})

		self.assertTrue(len(cards.find({'_id': card_id})) == 0)

		updated = boards.find({'name': 'Personal'})[0]['lists'][str(todo_id)]
		self.assertTrue(str(other_card_id) in updated['cards'])
		self.assertFalse(str(card_id) in updated['cards'])
		self.assertTrue(updated['ccount'] == 1)

	def test_comments(self):
		mdb = mongodb.Service(self._cl.service('mdb1'))

		# With a board, list, and card
		boards = mdb.database('planner').collection('boards')
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})
		personal_board = boards.find({'name': 'Personal'})[0]

		todo_id = ObjectId()
		boards.update({'_id': personal_board['_id']}, {'$set': {'lists.'+str(todo_id): {'ccount': 0}}})

		card_id = ObjectId()
		boards.update({
			'_id': personal_board['_id']},
			{'$set': {'lists.'+str(todo_id)+'.cards.'+str(card_id): {"_id": card_id, "text": "get groceries", "idx": 0}},
			'$inc': {'lists.'+str(todo_id)+'.ccount': 1}})

		cards = mdb.database('planner').collection('cards')
		cards.insert({'_id': card_id, 'author': self._cl.user()['_id'], 'summary': 'get groceries'})

		# Adding a comment should work
		comment_id = ObjectId()
		cards.update({
			'_id': card_id},
			{'$addToSet': {
				'comments': {
					'_id': comment_id, 'summary': 'sgtm', 'author_id': self._cl.user()['_id']}}})

		comment_id_2 = ObjectId()
		cards.update({
			'_id': card_id},
			{'$addToSet': {
				'comments': {
					'_id': comment_id_2, 'summary': 'yeah?', 'author_id': self._cl.user()['_id']}}})

		# Removing a comment should work
		cards.update({'_id': card_id}, {'$pull': {'comments': {'_id': comment_id}}})
		card = cards.find({'_id': card_id})[0]
		self.assertTrue(len(card['comments']) == 1)
		self.assertTrue(card['comments'][0]['_id'] == comment_id_2)


if __name__ == '__main__':
	unittest.main()
