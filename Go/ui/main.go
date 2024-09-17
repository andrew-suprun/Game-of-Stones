package main

import (
	"game_of_stones/board"

	"gioui.org/app"
)

type cellState int

const (
	empty cellState = iota
	selected
	black
	white
)

type turn int

const (
	human turn = iota
	engine
)

type gameState struct {
	cells [board.Size][board.Size]cellState
}

func main() {
	state := make(chan *gameState, 1)
	state <- &gameState{}

	go runEngine(state)
	go runUi(state)
	app.Main()
}
