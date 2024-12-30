package main

import (
	"gioui.org/app"
)

type cmdStart struct{}
type cmdMakeMove string
type evMove string

func main() {
	commands := make(chan any, 1)
	events := make(chan any, 1)

	go runEngine(commands, events)
	go runUi(commands, events)
	app.Main()
}
