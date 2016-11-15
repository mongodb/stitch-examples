
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


def setup_auth_providers(app, config):
	auth_providers_key = 'authProviders'
	if auth_providers_key not in config:
		return

	for ap_pair in config[auth_providers_key].iteritems():
		ap_parts = ap_pair[0].split('/')
		ap = AuthProvider(app._conn, app_name, ap_parts[0], ap_parts[1])
		ap.enable()
		ap.set_config(ap_pair[1])
		ap.save()

def setup_variables(app, config):
	variables_key = 'variables'
	if variables_key not in config:
		return

	for var_pair in config[variables_key].iteritems():
		var_pair[1]['name'] = var_pair[0]
		app.save_variable(Variable.from_Config(var_pair[0], var_pair[1]))

def setup_app(app):

	with open(sys.argv[3]) as app_config_in:
		config = json.load(app_config_in)

	setup_auth_providers(app, config)
	setup_variables(app, config)

	# for svc in app_config.services:
	# 	svc_desc = app_config.services[svc]

	# 	if svc_desc['type'] == ses.Service.Type:
	# 		svc = ses.Service(app.new_service(svc, ses.Service.Type))
	# 		config = svc_desc['config']
	# 		svc.save_config(config['region'], config['access_key_id'], config['secret_access_key'])
	# 		for rule in svc_desc['rules']:
	# 			new_rule = svc.new_rule()

	# 			if 'name' in rule:
	# 				new_rule.name(rule['name'])

	# 			new_rule.priority(rule['priority'])
	# 			new_rule.actions(rule['actions'])
	# 			new_rule.build().save()
	# 		if 'variables' in svc_desc:
	# 			for var in svc_desc['variables']:
	# 				svc.save_variable(Variable.from_JSON(var))

	# 	# Create service
	# 	elif svc_desc['type'] == mongodb.Service.Type:
	# 		svc = mongodb.Service(app.new_service(svc, mongodb.Service.Type))

	# 		svc.save_config(svc_desc['config']['uri'])

	# 		for rule in svc_desc['rules']:
	# 			new_rule = svc.new_rule()
	# 			new_rule.priority(rule['priority'])
	# 			new_rule.actions(rule['actions'])
	# 			new_rule.namespace(rule['namespace'])

	# 			if 'validate' in rule:
	# 				new_rule.validate(rule['validate'])

	# 			if 'filter' in rule:
	# 				new_rule.filter(rule['filter'])

	# 			if 'fields' in rule:
	# 				include_fields=[]
	# 				mutable_fields=[]
	# 				all_mutable = False

	# 				if 'include' in rule['fields']:
	# 					include_fields = rule['fields']['include']

	# 				if 'mutable' in rule['fields']:
	# 					mutable_fields = rule['fields']['mutable']

	# 				if 'allMutable' in rule['fields']:
	# 					all_mutable = rule['fields']['allMutable']

	# 				new_rule.fields(mongodb.Fields(include_fields, mutable_fields, all_mutable))
				
	# 			new_rule.build().save()


if __name__ == '__main__':
	if len(sys.argv) < 4:
		print "Usage: setup_app.py <app-name> <config.json> <app_config.json> [--clean]"
		sys.exit(1)

	clean = False
	if len(sys.argv) == 5 and sys.argv[4] == '--clean':
		clean = True

	with open(sys.argv[2]) as config_in:
		config = json.load(config_in)

	creds = UserPass(config['user'], config['password'])
	cl = AdminClient(Connection(creds))

	app_name = sys.argv[1]

	if clean:
		print 'Cleaning up', app_name
		cl.app(app_name).delete()
	else:
		# Create a new app
		app = cl.new_app(app_name)
		setup_app(app)
