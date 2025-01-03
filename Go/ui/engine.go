package main

import (
	"fmt"
	"math/rand"
	"time"

	"game_of_stones/board"
	"game_of_stones/connect6"
	"game_of_stones/tree"
)

type engine struct {
	commands chan any
	events   chan any
	moves    []connect6.Move
	game     *connect6.Connect6
	tree     *tree.Tree[*connect6.Connect6, connect6.Move, float32]
}

func runEngine(commands chan any, events chan any) {
	(&engine{
		commands: commands,
		events:   events,
	}).run()
}

func (eng *engine) run() {

	for cmd := range eng.commands {
		switch cmd := cmd.(type) {
		case cmdStart:
			eng.game = connect6.NewGame(32)
			eng.tree = tree.NewTree(eng.game, 64, 50)

		case cmdMakeMove:
			move, _ := eng.game.ParseMove(string(cmd))
			eng.tree.CommitMove(move)
			eng.moves = append(eng.moves, move)
			eng.bestMove()
		}
	}
}

var i = 1

func (eng *engine) bestMove() {
	if len(eng.moves) == 1 {
		places := []string{}
		for j := range 3 {
			for i := range 3 {
				if i != 1 || j != 1 {
					places = append(places, fmt.Sprintf("%c%d", i+8+'a', board.Size-8-j))
				}
			}
		}

		idx := rand.Intn(8)
		place1 := places[idx]
		places[idx] = places[len(places)-1]
		place2 := places[rand.Intn(7)]
		moveStr := place1 + "-" + place2
		gameMove, _ := eng.game.ParseMove(moveStr)
		eng.tree.CommitMove(gameMove)
		eng.events <- evMove(moveStr)
		return
	}

	start := time.Now()
	for time.Since(start) < 2000*time.Millisecond {
		m, _ := eng.tree.Expand()
		if m.IsDecisive() {
			break
		}
	}

	move, s := eng.tree.BestMove()
	fmt.Printf("%2d: %#v s: %d\n", i, move, s)
	i++
	eng.tree.CommitMove(move)
	eng.events <- evMove(move.String())
}

func (ev evMove) String(x1, y1, x2, y2 int) string {
	return fmt.Sprintf("%c%d-%c%d", x1+'a', board.Size-y1, x2+'a', board.Size-y2)

}
