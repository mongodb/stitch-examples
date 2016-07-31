### Setup

Download and run the baas server, with a mongodb instance running on localhost:27017.
Your authProviderConfigFile should look like
```
{
	"supported": ["oauth2/google", "oauth2/facebook"],
	"configs": {
		"oauth2/google": {
			"clientId": "CLIENT-ID",
			"clientSecret": "CLIENT-SECRET"
		},
		"oauth2/facebook": {
			"clientId": "CLIENT-ID",
			"clientSecret": "CLIENT-SECRET"
		}
	}
}
```

```
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

