//go:build connect6

package main

import (
	"fmt"
	"game_of_stones/connect6"
	"game_of_stones/tree"
	"math/rand"
	"time"
)

type move = connect6.Move

type engine struct {
	title    string
	game     *connect6.Connect6
	tree     *tree.Tree[connect6.Move, int16]
	duration time.Duration
}

func newEngine(title string) *engine {
	maxPlaces, maxMoves, expFactor, duration := parseTitle(title)
	aGame := connect6.NewGame(maxPlaces)
	aTree := tree.NewTree(aGame, maxMoves, expFactor)
	return &engine{
		title:    title,
		game:     aGame,
		tree:     aTree,
		duration: time.Duration(duration) * time.Millisecond,
	}
}

func moves() []string {
	rnd := rand.New(rand.NewSource(time.Now().UnixNano()))
	// rnd := rand.New(rand.NewSource(1))
	placeMap := map[string]struct{}{}
	for len(placeMap) < 5 {
		place := fmt.Sprintf("%c%d", rnd.Intn(9)+'f', rnd.Intn(9)+6)
		placeMap[place] = struct{}{}
	}
	places := []string{}
	for place := range placeMap {
		places = append(places, place)
	}
	moves := [3]string{}
	moves[0] = places[0] + "-" + places[0]
	moves[1] = places[1] + "-" + places[2]
	moves[2] = places[3] + "-" + places[4]

	return moves[:]
}
