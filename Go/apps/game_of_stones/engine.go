package main

import (
	"fmt"
	"math/rand"
	"time"

	. "game_of_stones/common"
	"game_of_stones/game"
	"game_of_stones/tree"
)

func runEngine(playerStones Turn, in, out chan string) {
	var (
		playerTurn      = First
		oppPlayerStones Turn
		theGame         *game.Game
		theTree         *tree.Tree[game.Move]
	)

	theGame = game.NewGame(22)
	theTree = tree.NewTree[game.Move](theGame, 64, 20)
	if playerStones == First {
		oppPlayerStones = Second
	} else {
		oppPlayerStones = First
	}

	firstMove := true

	for {
		if playerTurn == playerStones {
			var move game.Move
			nSims := 0
			if firstMove {
				firstMove = false
				if playerTurn == First {
					move, _ = game.ParseMove("j10")
				} else {
					move, _ = game.ParseMove(firstWhiteMove())
				}
			} else {
				timestamp := time.Now()
				for {
					dec, done := theTree.Expand()
					if done || dec != NoDecision || time.Since(timestamp) > time.Second {
						break
					}
				}
				dec := theGame.Decision()
				if dec != NoDecision {
					move = theTree.BestMove()
					return
				}
			}
			fmt.Printf("engine: playing move %v; sims %d\n", move, nSims)
			theTree.CommitMove(move)
			playerTurn = oppPlayerStones
			dec := theGame.Decision()
			if dec != NoDecision {
				out <- move.String() + ";terminal"
			} else {
				out <- move.String()
			}
		} else {
			incoming := <-in
			move, err := game.ParseMove(incoming)
			if err != nil {
				out <- fmt.Sprintf("engine: received invalid move %q, ignored", incoming)
			} else {
				theTree.CommitMove(move)
				playerTurn = playerStones
			}
		}
	}
}

func firstWhiteMove() string {
	if game.GameName == "gomoku" {
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
