---
title: Writing golang REST client to query netapp API
description: I needed a tool to migrate all network interfaces quickly
date: 2021-06-23
---

## Introduction

Yesterday I had to prepare a maintenance operation on one of my employers' netapp FAS8200 clusters. This cluster has two nodes, each with two uplinks using LACP. All these uplinks had to be moved to a new pair of switches : goodbye juniper EX4200, hello arista 7050SX3!

To make sure the operation is without disruption we needed to migrate all lifs (virtual network interfaces that serve NFS traffic) before disconnecting a node. The cluster has 137 such lifs, so manually migrating those was out of question.

Fortunately our netapp clusters are kept up to date by yours truly so we have access to the modern netapp api's. If that had not been the case I would have had to script the lif migrations by issuing cli commands and parsing the outputs... It could have worked but it would not have been clean and subject to breaking when lif names get too long or garbled, error handling would have suffered, etc.

A few years ago I would have done it in perl, but perl jobs being in decline I try to force myself to write more golang whenever I have the opportunity. I also could have leveraged existing libraries but just wanted to perform this exercise by myself. I had a few hours before me and was confident it would be more than enough to write and test it. Also I wanted something to blog about ;-)

## A little golang lib

First let's create a simple golang project :
```sh
mkdir netapp-lif-migrate
cd !$
go mod init !$
mkdir lib
```

Since we are going to need a few tools, I split those in a lib folder.

### lib/client.go

This is some boilerplate to have a clean REST client :
```golang
package lib

import (
	"fmt"
	"net/http"
	"time"
)

type Client struct {
	baseURL    string
	httpClient *http.Client
}

func NewClient(login string, password string, url string) *Client {
	return &Client{
		baseURL: fmt.Sprintf("https://%s:%s@%s/api", login, password, url),
		httpClient: &http.Client{
				Timeout: time.Minute,
		},
	}
}
```

### lib/model.go

Here we write some data structures to parse api responses for the few objects we are going to need :
```golang
package lib

type Lif struct {
	UUID     string   `json:"uuid"`
	Name     string   `json:"name"`
	Location Location `json:"location"`
}

type Location struct {
	Node     Node `json:"node"`
	HomeNode Node `json:"home_node"`
}

type Node struct {
	Name string `json:"name"`
}
```

### lib/lif.go

Here comes the two api calls we need : one to fetch the lif's status and one to migrate a lif. Error handling is kept simple :
```golang
package lib

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

type LifsResponse struct {
	Records []Lif `json:"records"`
}

func (c *Client) GetAllLifs() ([]Lif, error) {
	request := fmt.Sprintf("%s/network/ip/interfaces?fields=name,location.home_node.name,location.node.name", c.baseURL)
	req, err := http.NewRequest("GET", request, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Add("Accept", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		var data LifsResponse
		if err = json.NewDecoder(resp.Body).Decode(&data); err != nil {
				return nil, err
		}
		return data.Records, nil
	} else {
		return nil, err
	}
}

func (c *Client) MigrateLif(uuid string, targetNode string) error {
	request := fmt.Sprintf("%s/network/ip/interfaces/%s", c.baseURL, uuid)
	fmt.Println(request)
	req, err := http.NewRequest("PATCH", request,
		strings.NewReader(fmt.Sprintf(`{ "location": { "node": { "name": "%s" } } }`, targetNode))
	)
	if err != nil {
		return err
	}
	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Accept", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		return nil
	} else {
		return fmt.Errorf("http error: %d", resp.StatusCode)
	}
}
```

### lib/password.go

The last piece to our lib is some code to prompt for a password on the terminal :
```golang
package lib

import (
	"fmt"
	"os"

	"golang.org/x/term"
)

func AskPassword(message string) (string, error) {
	// Print message
	fmt.Printf("%s: ", message)

	// Set the terminal for password input
	oldState, err := term.MakeRaw(int(os.Stdin.Fd()))
	if err != nil {
		return "", err
	}
	defer term.Restore(int(os.Stdin.Fd()), oldState)

	// Ask for the netapp's password
	password, err := term.ReadPassword(int(os.Stdin.Fd()))
	if err != nil {
		return "", err
	}
	return string(password), nil
}
```

## Getting all lifs' status

With our simple lib, we can isolate the operations in individual scripts. I did not want to handle arguments, I wanted just simple scripts to execute with as little room for errors as possible : one script for each task. All this netapp migration is just a small part of a four hours maintenance by night, I needed the simplicity to avoid any potential mistake or in case I was not the one operating.

Here is the script to query the netapp's status :
```golang
package main

import (
	"fmt"
	"log"
	"netapp-lif-migrate/lib"
	"os"
)

func main() {
	password, err := lib.AskPassword("Password for admin@mut-CT-02")
	if err != nil {
		log.Println("Error when asking for password: %+v", err)
		os.Exit(1)
	}
	client := lib.NewClient("admin", password, "mut-ct-02.example.com")
	lifs, err := client.GetAllLifs()
	if err != nil {
		log.Println("Error getting all lifs: %+v", err)
		os.Exit(2)
	}
	for i := 0; i < len(lifs); i++ {
		isHome := "yes"
		if lifs[i].Location.HomeNode.Name != lifs[i].Location.Node.Name {
				isHome = "no"
		}
		fmt.Printf("home: %s, \tname: %s, \thome_node: %s, \tcurrent_node: %s\n",
				isHome,
				lifs[i].Name,
				lifs[i].Location.HomeNode.Name,
				lifs[i].Location.Node.Name,
		)
	}
}
```

## Migrate all lifs to a node

I had two copies of the following script, one for each node which differ only with the targetNode content :
```golang
package main

import (
	"fmt"
	"log"
	"netapp-lif-migrate/lib"
	"os"
)

targetNode := "mut-CT-02-01"

func main() {
	password, err := lib.AskPassword("Password for admin@mut-CT-02")
	if err != nil {
		log.Println("Error when asking for password: %+v", err)
		os.Exit(1)
	}
	client := lib.NewClient("admin", password, "mut-ct-02.example.com")
	lifs, err := client.GetAllLifs()
	if err != nil {
		log.Println("Error getting all lifs: %+v", err)
		os.Exit(2)
	}
	for i := 0; i < len(lifs); i++ {
		if lifs[i].Location.Node.Name != targetNode {
				err = client.MigrateLif(lifs[i].UUID, targetNode)
				if err == nil {
					fmt.Printf("Migrated %s\n", lifs[i].Name)
				} else {
					fmt.Printf("Failed to migrate %s\n", lifs[i].Name)
				}
		}
	}
}
```

## Send everyone home

The final script is one that takes all lifs that are not on their home port and send them to it :
```golang
package main

import (
	"fmt"
	"log"
	"netapp-lif-migrate/lib"
	"os"
)

func main() {
	password, err := lib.AskPassword("Password for admin@mut-CT-02")
	if err != nil {
		log.Println("Error when asking for password: %+v", err)
		os.Exit(1)
	}
	client := lib.NewClient("admin", password, "mut-ct-02.example.com")
	lifs, err := client.GetAllLifs()
	if err != nil {
		log.Println("Error getting all lifs: %+v", err)
		os.Exit(2)
	}
	for i := 0; i < len(lifs); i++ {
		if lifs[i].Location.Node.Name != lifs[i].Location.HomeNode.Name {
				err = client.MigrateLif(lifs[i].UUID, lifs[i].Location.HomeNode.Name)
				if err == nil {
					fmt.Printf("Migrated %s\n", lifs[i].Name)
				} else {
					fmt.Printf("Failed to migrate %s\n", lifs[i].Name)
				}
		}
	}
}
```

## Conclusion

This was a great golang exercise and the maintenance operation was a success.

I tried to parallelize the migration calls but I kept getting rate limited by the netapp so I settled on a simple sequential approach.
