package main

import (
	"fmt"
	"game_of_stones/board"
	"game_of_stones/turn"
	"math/rand"
	"time"
)

type searchTree interface {
	CommitMove(move string)
	BestMove() string
	Expand() int
}

type engine struct {
	gameId    int
	maxMoves  int
	maxPlaces int
	maxSims   int
	sims      int
	expFactor float64
	msPerMove time.Duration
	stones    turn.Turn
	turn      turn.Turn
	oppIn     chan string
	oppOut    chan string
	tree      searchTree
}

func newEngine(
	gameId int,
	stones turn.Turn,
	maxSims int,
	msPerMove time.Duration,
	oppIn chan string,
	oppOut chan string,
) *engine {
	self := &engine{
		gameId:    gameId,
		stones:    stones,
		maxSims:   maxSims,
		msPerMove: msPerMove,
		oppIn:     oppIn,
		oppOut:    oppOut,
	}

	if self.turn == self.stones {
		if gameId == connect6Id {
			self.tree.CommitMove("j10-j10")
			oppOut <- "j10-j10"
		} else {
			self.tree.CommitMove("j10")
			oppOut <- "j10"
		}
		self.turn = turn.Second

	}
	go self.opponentMoves()

	return self
}

func (self *engine) opponentMoves() {
	for {
		move := <-self.oppIn
		if self.turn == self.stones {
			continue
		}
		self.tree.CommitMove(move)
		if self.turn == turn.First {
			self.turn = turn.Second
		} else {
			self.turn = turn.First
		}
	}
}

func firstWhiteConnect6Move() string {
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+8+'a', board.Size-8-j))
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

func firstWhiteGomokuMove() string {
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+8+'a', board.Size-8-j))
			}
		}
	}

	return places[rand.Intn(8)]
}
