### Setup

Download and run the baas server, with a mongodb instance running on localhost:27017.

```
	go get github.com/erh/baas
	go run src/github.com/erh/baas/examples/todo/server.go
```

Set up the sample app dev server:

```
	cd baas/src/github.com/erh/baas/examples/todo/
	npm install
	npm start
```

In a browser, open up localhost:8000.

