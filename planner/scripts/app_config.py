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
					"insert", "find", "delete"
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
						"owner_id"
					],
					"allMutable": False
				}
			},

			{
				"priority": 1,
				"actions": [
					"insert",
				],
				"namespace": "planner.lists",
				# "filter": {
				# 	"board_id": {"$in": "$var.own_boards._id"},
				# },
				# "validate": {
				# 	"name": {
				# 		"$ne": ""
				# 	},
				# 	"board_id": {"$in": "$var.own_boards._id"},
				# },
				"fields": {
					"mutable": [
						"name",
						"board_id"
					],
					"allMutable": False
				}
			},
		]
	}
}