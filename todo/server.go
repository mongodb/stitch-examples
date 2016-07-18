package main

import (
	"github.com/erh/baas/action/builtin/mongodb"
	"github.com/erh/baas/action/builtin/simple"
	"github.com/erh/baas/api"

	"fmt"
	"net/http"
	"os"
)

func main() {
	reg := simple.NewRegistry()

	reg.Register(simple.NewApp(
		"test",
		[]simple.NamedService{{"mdb1", mongodb.New(mongodb.Settings{Url: "mongodb://localhost:27017"})}},
		nil,
		nil))
	apiSrv := api.New(reg)
	err := http.ListenAndServe(":8080", apiSrv.Handler())
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
