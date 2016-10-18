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

	# def test_boards(self):
	# 	mdb = mongodb.Service(self._cl.service('db'))

	# 	# Create board
	# 	boards = mdb.database('planner').collection('boards')
	# 	boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})

	# 	# # Create board twice should fail
	# 	# with self.assertRaisesRegexp(Error, 'Failed validation'):
	# 	# 	boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})

	# 	# Create board without name should fail
	# 	with self.assertRaisesRegexp(Error, 'Failed validation'):
	# 		boards.insert({'owner_id': self._cl.user()['_id']})

	# 	# Create board without valid name should fail
	# 	with self.assertRaisesRegexp(Error, 'Failed validation'):
	# 		boards.insert({'name': '', 'owner_id': self._cl.user()['_id']})

	# 	# Create board without valid owner_id should fail
	# 	with self.assertRaisesRegexp(Error, 'Failed validation'):
	# 		boards.insert({'name': '', 'owner_id': 'myid'})

	# 	# Create some other board
	# 	self._m_client.boards.boards.insert_one({'name': 'Personal', 'owner_id': ObjectId()})

	# 	# Finding own board should work
	# 	personal = boards.find({'name': 'Personal'})
	# 	self.assertTrue(len(personal) == 1)
	# 	personal = personal[0]
	# 	self.assertTrue(personal['owner_id'] == self._cl.user()['_id'])

	# 	# Deleting own board should work
	# 	boards.remove({'_id': personal['_id']})
	# 	self.assertTrue(len(boards.find({'name': 'Personal'})) == 0)

	# 	# Other board should still exist
	# 	other = self._m_client.boards.boards.find_one({'name': 'Personal'})
	# 	self.assertTrue(other['owner_id'] != self._cl.user()['_id'])

	# 	# TODO(erd): CRUD members

	# def test_lists(self):
	# 	mdb = mongodb.Service(self._cl.service('db'))

	# 	# With a board
	# 	boards = mdb.database('planner').collection('boards')
	# 	boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})
	# 	personal_board = boards.find({'name': 'Personal'})[0]

	# 	# Adding a new list should work
	# 	boards.update({'_id': personal_board['_id']}, {'$set': {'lists.todo': {}}})

	# 	# Adding a new list with a bad name should fail
	# 	# TODO(erd): Needs a rule that can describe this

	# 	# Removing a list should work
	# 	boards.update({'_id': personal_board['_id']}, {'$set': {'lists.other': {}}})
	# 	boards.update({'_id': personal_board['_id']}, {'$unset': {'lists.todo': True}})

	# 	updated = boards.find({'name': 'Personal'})[0]
	# 	self.assertTrue('other' in updated['lists'])
	# 	self.assertFalse('todo' in updated['lists'])

	def test_cards(self):
		mdb = mongodb.Service(self._cl.service('db'))

		# With a board and list
		boards = mdb.database('planner').collection('boards')
		boards.insert({'name': 'Personal', 'owner_id': self._cl.user()['_id']})
		personal_board = boards.find({'name': 'Personal'})[0]

		# TODO(erd): This should have a rule to enforce count is >= 0
		boards.update({'_id': personal_board['_id']}, {'$set': {'lists.todo': {'count': 0}}})
		personal_board = boards.find({'name': 'Personal'})[0]

		num_cards = personal_board['lists']['todo']['count']

		# Adding a new card should work
		card_id = ObjectId()
		idx_1 = num_cards
		boards.update({
			'_id': personal_board['_id']},
			{'$set': {'lists.todo.cards.'+str(card_id): {"_id": card_id, "text": "hello", "idx": idx_1}},
			'$inc': {'lists.todo.count': 1}})

		personal_board = boards.find({'name': 'Personal'})[0]
		num_cards = personal_board['lists']['todo']['count']

		other_card_id = ObjectId()
		idx_2 = num_cards
		boards.update({
			'_id': personal_board['_id']},
			{'$set': {'lists.todo.cards.'+str(other_card_id): {"_id": other_card_id, "text": "it's me", "idx": idx_2}},
			'$inc': {'lists.todo.count': 1}})

		# Swapping two cards should work
		boards.update({
			'_id': personal_board['_id']},
			{'$set': {'lists.todo.cards.'+str(card_id)+'.idx': idx_2, 'lists.todo.cards.'+str(other_card_id)+'.idx': idx_1}})


if __name__ == '__main__':
	unittest.main()
