package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"os"

	. "github.com/erh/baas"
	"github.com/erh/baas/action/builtin/mongodb"
	"github.com/erh/baas/action/builtin/simple"
	"github.com/erh/baas/api"
	"github.com/erh/baas/auth"
	"github.com/erh/baas/auth/builtin/oauth2/google"
)

var config = `
{
	"apiServer": {
		"port": 8080
	},
	"auth": {
		"saml": {
			"spCertPath": "./test_data/saml_sp.crt",
			"spKeyPath": "./test_data/saml_sp.key"
		},
		"cookieHashKey": "F+43gQpES4aoi9U+8t1V1KWqtsldNh+fqZBvOhaVPRt814FPGNtPKLthy2ty/Vc0",
		"cookieBlockKey": "jTMu3vNVyGy4MNLs/GEdHrif1FG7HSYh",
		"jwtSigningKey": "K!@#JIJ!@#*LANNZK!@#IOJDLWJRGG^!G#NCBGAS"
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

	if err := json.Unmarshal([]byte(config), &GlobalConfig); err != nil {
		panic(err)
	}

	reg := simple.NewRegistry()

	reg.Register(simple.NewApp(
		"test",
		[]simple.NamedService{{"mdb1", mongodb.New(mongodb.Settings{Url: "mongodb://localhost:27017"})}},
		[]auth.ProviderName{google.Name},
		map[auth.ProviderName]auth.ProviderConfig{
			google.Name: auth.ProviderConfig{
				"clientId":     *googleClientId,
				"clientSecret": *googleClientSecret,
			},
		}))
	apiSrv := api.New(reg)
	err := http.ListenAndServe(":8080", apiSrv.Handler())
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
