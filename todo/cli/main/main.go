package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/10gen/baas/clients/golang"
	"github.com/mitchellh/go-homedir"
)

const (
	appName    = "todo"
	baasUrl    = "https://baas-dev.10gen.cc"
	checkBox   = "\xE2\x98\x90"
	checkedBox = "\xE2\x98\x91"
)

func main() {
	c, err := getClient()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	msc := client.MongoServiceClient{
		"todo", // App name
		"mdb1", // Service name
		*c,
	}

	type item struct {
		Text    string `json:"text"`
		Checked bool   `json:"checked"`
	}
	out := []item{}
	err = msc.DB("todo").C("items").Find(nil).All(&out)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	fmt.Println("todo list items:")
	for _, i := range out {
		status := checkBox
		if i.Checked {
			status = checkedBox
		}
		fmt.Printf("%s - %s\n", status, i.Text)
	}
}

func promptLogin(c *client.Client) {
	authInfo, err := c.AppAuthInfo(appName)
	if err != nil {
		fmt.Println("error fetching auth methods for app", err)
		return
	}
	fmt.Printf("Supported auth methods:\n\n")
	for k, _ := range authInfo {
		fmt.Println("\t", k)
		fmt.Println("\t\t", fmt.Sprintf("%s/v1/app/%s/auth/%s?short=true\n", baasUrl, appName, k))
	}

}

func getClient() (*client.Client, error) {
	c := &client.Client{baasUrl, nil, nil}
	home, err := homedir.Dir()
	if err != nil {
		return nil, err
	}

	confPath := filepath.Join(home, ".baas.yml")
	cf, err := os.Open(confPath)
	if err != nil {
		if os.IsNotExist(err) {
			fmt.Println("No creds found - log in and copy the token info to ~/.baas.yml")
			promptLogin(c)
			os.Exit(1)
			return nil, nil
		}
		return nil, err
	}
	defer cf.Close()

	dec := json.NewDecoder(cf)
	creds := client.Credentials{}
	err = dec.Decode(&creds)
	if err != nil {
		return nil, err
	}
	c.Authenticator = &client.RefreshTokenAuth{baasUrl, creds.RefreshToken}
	err = c.AuthenticateApp(appName)
	if err != nil {
		return nil, err
	}
	return c, nil
}
