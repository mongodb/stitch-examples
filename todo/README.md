### Setup


Download and run the BaaS server, with a mongodb instance running on localhost:27017.

```
go get github.com/10gen/baas
cd src/github.com/10gen/baas
go run main/main.go -configFile examples/server_config.json
```

Edit examples/todo/app_config.json and replace the OAuth credentials with your own.

Make a creds.json file containing the admin credentials for your BaaS deployment:
```
{
   user: "unique_user@domain.com",
   password: "password"
}
```

Use the import tool to create the app:

```
pip install clients/python/
python tools/import_tool.py "todo" ./creds.json ./examples/todo/app_config.json
```

Install dependencies for the sample app, and start it:
```
cd examples/todo
npm install
npm start
```

In a browser, open up localhost:8001.

