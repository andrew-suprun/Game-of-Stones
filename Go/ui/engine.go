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
	root     *tree.Tree[*connect6.Connect6, connect6.Move]
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
			eng.root = tree.NewTree(eng.game, 1000)

		case cmdMakeMove:
			move := connect6.MakeMove(cmd[0], cmd[1], cmd[2], cmd[3], 0)
			eng.game.PlayMove(move)
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

		gameMove := connect6.MakeMove(m1.x, m1.y, m2.x, m2.y, 0)
		eng.game.PlayMove(gameMove)
		eng.events <- evMove([4]int{m1.x, m1.y, m2.x, m2.y})
		return
	}
	move := eng.root.BestMove()

	start := time.Now()
	i := 1
	for time.Since(start) < 2*time.Second {
		eng.root.expand()
		move = eng.root.BestMove()
		fmt.Println("best move", move, i)
		i++
	}

	eng.game.PlayMove(move)
	eng.events <- evMove([4]int{move.x1, move.y1, move.x2, move.y2})
}
