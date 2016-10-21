
from pybaas.client import Error
from pybaas import AdminClient, APIClient, Connection
from pybaas.auth import UserPass
import pybaas.svcs.mongodb as mongodb
import pybaas.svcs.ses as ses
from pybaas.auth_provider import AuthProvider
from pybaas.variable import Variable

from pymongo import MongoClient

import sys
import json
import imp


def setUp(app):

	app_config = imp.load_source('', sys.argv[3])

	for ap_name in app_config.auth_providers:
		ap = ap_name.split('/')
		ap = AuthProvider(app._conn, app_name, ap[0], ap[1])
		ap.enable()
		ap.set_config(app_config.auth_providers[ap_name])
		ap.save()

	for svc in app_config.services:
		svc_desc = app_config.services[svc]

		if svc_desc['type'] == ses.Service.Type:
			svc = ses.Service(app.new_service(svc, ses.Service.Type))
			config = svc_desc['config']
			svc.save_config(config['region'], config['access_key_id'], config['secret_access_key'])
			for rule in svc_desc['rules']:
				new_rule = svc.new_rule()
				new_rule.priority(rule['priority'])
				new_rule.actions(rule['actions'])
				new_rule.build().save()
			if 'variables' in svc_desc:
				for var in svc_desc['variables']:
					svc.save_variable(Variable.from_JSON(var))

		# Create service
		elif svc_desc['type'] == mongodb.Service.Type:
			svc = mongodb.Service(app.new_service(svc, mongodb.Service.Type))

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


if __name__ == '__main__':
	if len(sys.argv) < 4:
		print "Usage: setup.py <app-name> <config.json> <app_config.py> [--clean]"
		sys.exit(1)

	clean = False
	if len(sys.argv) == 5 and sys.argv[4] == '--clean':
		clean = True

	with open(sys.argv[2]) as data_in:
		data = json.load(data_in)

	creds = UserPass(data['user'], data['password'])
	cl = AdminClient(Connection(creds))

	app_name = sys.argv[1]

	if clean:
		print 'Cleaning up', app_name
		cl.app(app_name).delete()
	else:
		# Create a new app
		app = cl.new_app(app_name)
		setUp(app)
