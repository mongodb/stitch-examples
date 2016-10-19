from pybaas.svcs import mongodb

auth_providers={
	'local/userpass': {},
	'oauth2/facebook': {
		"metadataFields": ["email"],
		"clientId": "APP-ID",
		"clientSecret": "APP-SECRET"
	},
}

services={
	'mdb1': {
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
					"owner_id": "$var.$auth.id",
					"lcount": {"$gte": 0}
				},
				"fields": {
					"mutable": [
						"name",
						"owner_id",
						"lists",
						"lcount"
					],
					"allMutable": False
				}
			},
			{
				"priority": 1,
				"actions": [
					"insert", "delete", "update"
				],
				"namespace": "planner.cards",
				"filter": {
					"author": "$var.$auth.id",
				},
				"validate": {
					"text": {
						"$ne": ""
					},
					"author": "$var.$auth.id"
				},
				"fields": {
					"mutable": [
						"_id",
						"author",
						"text",
						"comments",
					],
					"allMutable": False
				}
			},
			{
				"priority": 2,
				"actions": [
					"find"
				],
				"namespace": "planner.cards",
			},
		]
	}
}