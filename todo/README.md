### Setup

Download and run the baas server, with a mongodb instance running on localhost:27017.
Configure the app_config.json and replace the OAuth credentials with your own.

```
	mongoimport --host localhost:27017 --db app --collection apps app_config.json
	go get github.com/erh/baas
	cd ./baas/src/github.com/erh/baas
	go run ./api/main/main.go --configFile ./examples/server_config.json --authProviderConfigFile file.json
```

Set up the sample app dev server:

```
	cd ./examples/todo/
	npm install
	npm start
```

In a browser, open up localhost:8000.

