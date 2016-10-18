from pybaas.svcs import mongodb

auth_providers={
	'local/userpass': {},
}

services={
	'db': {
		'type': mongodb.Service.Type,
		'config': {
			'uri': 'mongodb://localhost:27017'
		},
		'rules': [
			{
				"priority": 0,
				"actions": [
					"insert", "find", "delete", "update"
				],
				"namespace": "planner.boards",
				"filter": {
					"owner_id": "$var.$auth.id",
				},
				"validate": {
					"name": {
						"$ne": ""
					},
					"owner_id": "$var.$auth.id"
				},
				"fields": {
					"mutable": [
						"name",
						"owner_id",
						"lists"
					],
					"allMutable": False
				}
			},
		]
	}
}