### Setup

Download and run the baas server, with a mongodb instance running on localhost:27017.
Configure the app_config.json and replace the OAuth credentials with your own.

Make a creds.json file containing the admin credentials for your admin deployment.

```
	python import_tool.py "todo" ./creds.json ./app_config.json
	go get github.com/10gen/baas
	cd ./baas/src/github.com/10gen/baas
	go run ./api/main/main.go --configFile ./examples/server_config.json --authProviderConfigFile file.json
```

Set up the sample app dev server:

```
	cd ./examples/todo/
	npm install
	npm start
```

In a browser, open up localhost:8000.

