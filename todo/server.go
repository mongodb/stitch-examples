package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"

	"github.com/erh/baas/action/builtin/mongodb"
	"github.com/erh/baas/action/builtin/simple"
	"github.com/erh/baas/api"
	"github.com/erh/baas/auth"
	"github.com/erh/baas/auth/builtin/oauth2/google"
	"github.com/erh/baas/config"

	"gopkg.in/mgo.v2/bson"
)

var confStr = `
{
	"auth": {
		"saml": {
			"enabled": false
		},
			"authRequest": {
			"cookieHashKey": "F+43gQpES4aoi9U+8t1V1KWqtsldNh+fqZBvOhaVPRt814FPGNtPKLthy2ty/Vc0",
			"cookieBlockKey": "jTMu3vNVyGy4MNLs/GEdHrif1FG7HSYh"
		},
		"session": {
			"store": "mongodb",
			"jwtSigningKey": "K!@#JIJ!@#*LANNZK!@#IOJDLWJRGG^!G#NCBGAS"
		},
		"user": {
			"store": "mongodb"
		}
	},
	"db": {
		"mongoDBURI": "mongodb://localhost:27017"
	}
}
`

var (
	googleClientId     = flag.String("googleClientId", "", "Google OAuth2 Client ID")
	googleClientSecret = flag.String("googleClientSecret", "", "Google OAuth2 Client Secret")
)

func main() {

	flag.Parse()
	if *googleClientId == "" || *googleClientSecret == "" {
		flag.Usage()
		os.Exit(1)
	}

	conf, err := config.Parse(confStr)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	reg := simple.NewRegistry()

	reg.Register(simple.NewApp(
		"test",
		bson.ObjectIdHex("5798ce26772e2e205627c273"),
		[]simple.NamedService{{"mdb1", mongodb.New(mongodb.Settings{Url: "mongodb://localhost:27017"})}},
		[]auth.ProviderName{google.Name},
		map[auth.ProviderName]auth.ProviderConfig{
			google.Name: auth.ProviderConfig{
				"clientId":     *googleClientId,
				"clientSecret": *googleClientSecret,
			},
		}))

	apiSrv, err := api.New(conf, reg)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if err := http.ListenAndServe(":8080", apiSrv.Handler()); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
