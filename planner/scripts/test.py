import unittest

from pybaas.client import Error
from pybaas import AdminClient, APIClient, Connection
from pybaas.auth import UserPass
import pybaas.svcs.mongodb as mongodb
from pybaas.auth_provider import AuthProvider
from pybaas.variable import Variable

from bson.objectid import ObjectId

from pymongo import MongoClient

import app_config

class TestMethods(unittest.TestCase):

	def setUp(self):

		# Clear data
		client = MongoClient()
		client.drop_database('planner')
		self._m_client = client

		creds = UserPass('unique_user@domain.com', 'password')
		cl = AdminClient(Connection(creds))

		app_name = str(ObjectId())
		self._app = cl.new_app(app_name)

		for ap_name in app_config.auth_providers:
			ap = ap_name.split('/')
			ap = AuthProvider(self._app._conn, app_name, ap[0], ap[1])
			ap.enable()
			ap.set_config(app_config.auth_providers[ap_name])
			ap.save()

		for svc in app_config.services:
			svc_desc = app_config.services[svc]

			# Create service
			if svc_desc['type'] == mongodb.Service.Type:
				svc = mongodb.Service(self._app.new_service(svc, mongodb.Service.Type))

				svc.save_config(svc_desc['config']['uri'])

				for rule in svc_desc['rules']:
					new_rule = svc.new_rule()
					new_rule.priority(rule['priority'])
					new_rule.actions(rule['actions'])
					new_rule.namespace(rule['namespace'])

					if 'validate' in rule:
						new_rule.validate(rule['validate'])

					if 'filter' in rule:
						new_rule.filter(rule['filter'])

					if 'fields' in rule:
						include_fields=[]
						mutable_fields=[]
						all_mutable = False

						if 'include' in rule['fields']:
							include_fields = rule['fields']['include']

						if 'mutable' in rule['fields']:
							mutable_fields = rule['fields']['mutable']

						if 'allMutable' in rule['fields']:
							all_mutable = rule['fields']['allMutable']

						new_rule.fields(mongodb.Fields(include_fields, mutable_fields, all_mutable))
					
					new_rule.build().save()

				if 'variables' in svc_desc:
					for var in svc_desc['variables']:
						svc.save_variable(Variable.from_JSON(var))

		self._cl = APIClient(Connection(creds), app=app_name)

	def tearDown(self):
		self._app.delete()

	def test_boards(self):
		mdb = mongodb.Service(self._cl.service('mdb1'))

		# Create board
		# TODO(erd): This should have a rule to enforce count is >= 0
		boards = mdb.database('planner').collection('boards')
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id'], 'lcount': 0})

		# # Create board twice should fail
		# with self.assertRaisesRegexp(Error, 'Failed validation'):
		# 	boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id'], 'lcount': 0})

		# Create board without name should fail
		with self.assertRaisesRegexp(Error, 'Failed validation'):
			boards.insert({'owner_id': self._cl.user()['_id'], 'lcount': 0})

		# Create board without valid name should fail
		with self.assertRaisesRegexp(Error, 'Failed validation'):
			boards.insert({'name': '', 'owner_id': self._cl.user()['_id'], 'lcount': 0})

		# Create board without valid owner_id should fail
		with self.assertRaisesRegexp(Error, 'Failed validation'):
			boards.insert({'name': '', 'owner_id': 'myid', 'lcount': 0})

		# Create some other board
		self._m_client.boards.boards.insert_one({'name': 'Personal', 'owner_id': ObjectId(), 'lcount': 0})

		# Finding own board should work
		personal = boards.find({'name': 'Personal'})
		self.assertTrue(len(personal) == 1)
		personal = personal[0]
		self.assertTrue(personal['owner_id'] == self._cl.user()['_id'])

		# Deleting own board should work
		boards.remove({'_id': personal['_id']})
		self.assertTrue(len(boards.find({'name': 'Personal'})) == 0)

		# Other board should still exist
		other = self._m_client.boards.boards.find_one({'name': 'Personal'})
		self.assertTrue(other['owner_id'] != self._cl.user()['_id'])

		# TODO(erd): CRUD members

	def test_lists(self):
		mdb = mongodb.Service(self._cl.service('mdb1'))

		# With a board
		boards = mdb.database('planner').collection('boards')
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id'], 'lcount': 0})
		personal_board = boards.find({'name': 'Personal'})[0]

		num_lists = personal_board['lcount']

		# Adding a new list should work
		list_id = ObjectId()
		idx_1 = num_lists
		boards.update({'_id': personal_board['_id']}, 
			{'$set': {'lists.'+str(list_id): {'_id': list_id, 'name': 'todo', 'idx': num_lists}},
			'$inc': {'lcount': 1}})

		# Adding a new list with a bad name should fail
		# TODO(erd): Needs a rule that can describe this

		personal_board = boards.find({'name': 'Personal'})[0]
		num_lists = personal_board['lcount']

		# Swapping two lists should work
		other_id = ObjectId()
		idx_2 = num_lists
		boards.update({'_id': personal_board['_id']}, 
			{'$set': {'lists.'+str(other_id): {'_id': other_id, 'name': 'other', 'idx': num_lists}},
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
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id'], 'lcount': 0})
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
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id'], 'lcount': 0})
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
