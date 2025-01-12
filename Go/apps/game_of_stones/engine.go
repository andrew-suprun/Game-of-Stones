package main

import (
	"fmt"
	"game_of_stones/game"
	"game_of_stones/tree"
	"game_of_stones/turn"
	"math/rand"
	"os"
)

type engine struct {
	gameId game.GameName
	stones turn.Turn
	turn   turn.Turn
	game   *game.Game
	tree   *tree.Tree[game.Move]
}

func newEngine(gameId game.GameName, stones turn.Turn, in, out chan string) *engine {
	eng := &engine{
		gameId: gameId,
		stones: stones,
	}

	eng.game = game.NewGame(gameId, 22)
	eng.tree = tree.NewTree[game.Move](eng.game, 64, 20)

	state := make(chan *engine, 1)
	state <- eng

	go run(state, out)
	go opponentMoves(state, in)
	fmt.Println("engine started")

	return eng
}

func run(engineCh chan *engine, responseCh chan string) {
	firstMove := true
	for {
		engine := <-engineCh
		if engine.turn == engine.stones {
			if firstMove {
				firstMove = false
				if engine.turn == turn.First {
					move, _ := engine.game.ParseMove("j10")
					engine.tree.CommitMove(move)
					engine.turn = turn.Second
					responseCh <- move.String()
				} else {
					engine.turn = turn.Second
					move := firstWhiteMove(engine.gameId)
					fmt.Printf("first white move %q\n", move)
					responseCh <- move
				}
				if engine.stones == turn.First {
					engine.turn = turn.Second
				} else {
					engine.turn = turn.First
				}
				engineCh <- engine
				continue
			}
			if engine.stones == turn.First {
				engine.turn = turn.Second
			} else {
				engine.turn = turn.First
			}
			move := engine.tree.BestMove()
			responseCh <- move.String()
			engine.tree.CommitMove(move)
			engineCh <- engine
			continue
		}
		engine.tree.Expand()
		engineCh <- engine

	}
}

func opponentMoves(engineCh chan *engine, movesCh chan string) {
	for {
		moveStr := <-movesCh
		if moveStr == "stop" {
			fmt.Println("engine stopping")
			os.Exit(0)
		}
		engine := <-engineCh
		move, err := engine.game.ParseMove(moveStr)
		if err != nil {
			fmt.Printf("Failed to parse move %q", moveStr)
			os.Exit(1)
		}
		engine.tree.CommitMove(move)
		engine.turn = engine.stones
		engineCh <- engine
	}
}

func firstWhiteMove(gameId game.GameName) string {
	fmt.Println("firstWhiteMove: gameId", gameId)
	if gameId == gomokuId {
		return firstWhiteGomokuMove()
	}
	return firstWhiteConnect6Move()
}

func firstWhiteGomokuMove() string {
	fmt.Println("firstWhiteGomokuMove", gameId)
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+8+'a', game.Size-8-j))
			}
		}
	}

	fmt.Println("places", places)
	return places[rand.Intn(8)]
}

func firstWhiteConnect6Move() string {
	fmt.Println("firstWhiteConnect6Move", gameId)
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+8+'a', game.Size-8-j))
			}
		}
	}

	idx1 := rand.Intn(8)
	idx2 := idx1
	for idx1 == idx2 {
		idx2 = rand.Intn(8)
	}
	return places[idx1] + "-" + places[idx2]
}
