package main

import (
	"fmt"
	"math/rand"
	"time"

	"game_of_stones/game"
	"game_of_stones/tree"
	"game_of_stones/turn"
)

func runEngine(gameId game.GameName, playerStones turn.Turn, in, out chan string) {
	var (
		playerTurn      = turn.First
		oppPlayerStones turn.Turn
		theGame         *game.Game
		theTree         *tree.Tree[game.Move]
	)

	theGame = game.NewGame(gameId, 22)
	theTree = tree.NewTree[game.Move](theGame, 64, 20)
	if playerStones == turn.First {
		oppPlayerStones = turn.Second
	} else {
		oppPlayerStones = turn.First
	}

	firstMove := true

	for {
		if playerTurn == playerStones {
			var move game.Move
			nSims := 0
			if firstMove {
				firstMove = false
				if playerTurn == turn.First {
					move, _ = theGame.ParseMove("j10")
				} else {
					move, _ = theGame.ParseMove(firstWhiteMove(gameId))
				}
			} else {
				timestamp := time.Now()
				for {
					move, nSims = theTree.Expand()
					if move.IsDecisive() || time.Since(timestamp) > time.Second {
						move = theTree.BestMove()
						break
					}
				}
			}
			fmt.Printf("engine: playing move %#v; sims %d\n", move, nSims)
			theTree.CommitMove(move)
			playerTurn = oppPlayerStones
			if move.IsTerminal() {
				out <- move.String() + ";terminal"
			} else {
				out <- move.String()
			}
		} else {
			incoming := <-in
			move, err := theGame.ParseMove(incoming)
			if err != nil {
				out <- fmt.Sprintf("engine: received invalid move %q, ignored", incoming)
			} else {
				theTree.CommitMove(move)
				playerTurn = playerStones
			}
		}
	}
}

func firstWhiteMove(gameId game.GameName) string {
	if gameId == gomokuId {
		return firstWhiteGomokuMove()
	}
	return firstWhiteConnect6Move()
}

func firstWhiteGomokuMove() string {
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+8+'a', game.Size-8-j))
			}
		}
	}

	return places[rand.Intn(8)]
}

func firstWhiteConnect6Move() string {
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
