package main

import (
	"log"

	"{{MODULE_NAME}}/platform/cli/commands"
)

func main() {
	if err := commands.Execute("{{SERVICE_NAME}}"); err != nil {
		log.Fatal(err)
	}
}
