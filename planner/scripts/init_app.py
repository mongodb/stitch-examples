import json
import sys

from pybaas import AdminClient, Connection
from pybaas.auth import UserPass
from pybaas.svcs import mongodb, twilio, http
from pybaas.pipeline import Literal, Expression
import pybaas.variable as variable
from pybaas.auth_provider import OAuth2Google, OAuth2Facebook, UserPass as UP

def setup_auth(app):
	# Enable local/userpass
	UP(app).enable()

	# Enable OAuth 2.0
	google_p = OAuth2Google(app)
	google_p.enable()
	google_p.set_client_id(data['google']['clientId'])
	google_p.set_client_secret(data['google']['clientSecret'])
	google_p.save()

	facebook_p = OAuth2Facebook(app)
	facebook_p.enable()
	facebook_p.set_app_id(data['facebook']['appId'])
	facebook_p.set_app_secret(data['facebook']['appSecret'])
	facebook_p.save()

def setup_mongodb(app):
	mdb1 = mongodb.Service(app.new_service('mdb1', mongodb.Service.Type))
	mdb1.save_config(uri='mongodb://localhost:27017')

	p = 0
	for x in ["boards", "lists", "cards", "members"]:
	    mdb1.new_rule() \
	       .priority(p) \
	       .actions(['find', 'update', 'insert', 'delete', 'aggregate']) \
	       .namespace('planner.%s' % x) \
	       .fields(mongodb.Fields(all_mutable=True)) \
	       .build().save()
	    p += 1


if __name__ == "__main__":

	if len(sys.argv) < 3:
		print "Usage: example1.py <app-name> <config.json> [--clean]"
		sys.exit(1)

	clean = False
	if len(sys.argv) == 4 and sys.argv[3] == '--clean':
		clean = True

	with open(sys.argv[2]) as data_in:
		data = json.load(data_in)

	creds = UserPass(data['user'], data['password'])
	cl = AdminClient(Connection(creds))

	app_name = sys.argv[1]

	if clean:
		print 'Cleaning up', app_name
		app = cl.app(app_name)

		for service in app.services():
			print 'Deleting service', service.name()
			for rule in service.rules():
				print 'Deleting rule', rule.id()
				rule.delete()
			for variable in service.variables():
				print 'Deleting variable', variable.name()
				service.delete_variable(variable.name())
			for trigger in service.triggers():
				print 'Deleting trigger', trigger.id()
				trigger.delete()
			service.delete()

		app.delete()
	else:
		# Create a new app
		app = cl.new_app(app_name)

		setup_auth(app)
		setup_mongodb(app)
