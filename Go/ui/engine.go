package main

import (
	"fmt"
	"game_of_stones/connect6"
	"game_of_stones/tree"
	"math/rand"
	"time"
)

type engine struct {
	commands chan any
	events   chan any
	moves    []connect6.Move
	game     *connect6.Connect6
	root     *tree.SearchTree[connect6.Move]
}

func runEngine(commands chan any, events chan any) {
	(&engine{
		commands: commands,
		events:   events,
	}).run()
}

func (eng *engine) run() {
	fmt.Println("Run")
	for cmd := range eng.commands {
		fmt.Println("Cmd", cmd)
		switch cmd := cmd.(type) {
		case cmdStart:
			eng.game = connect6.NewGame()
			eng.root = tree.NewTree[connect6.Move](eng.game, 20)

		case cmdMakeMove:
			move := eng.game.MakeMove(cmd[0], cmd[1], cmd[2], cmd[3])
			eng.moves = append(eng.moves, move)
			eng.bestMove()
		}
	}
}

func (eng *engine) bestMove() {
	if len(eng.moves) == 1 {
		m := []move{}
		for j := range 3 {
			for i := range 3 {
				if i != 1 || j != 1 {
					m = append(m, move{i + 8, j + 8})
				}
			}
		}

		idx := rand.Intn(8)
		m1 := m[idx]
		m[idx] = m[len(m)-1]
		m2 := m[rand.Intn(7)]

		eng.events <- evMove([4]byte{byte(m1.x), byte(m1.y), byte(m2.x), byte(m2.y)})
	}
	move := eng.root.BestMove()
	start := time.Now()
	for time.Since(start) < 2*time.Second {
		eng.root.Expand()
		move = eng.root.BestMove()
	}
	eng.events <- evMove([4]byte{move.X1, move.Y1, move.X2, move.Y2})
}
