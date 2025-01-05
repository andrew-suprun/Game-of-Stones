//go:build gomoku

package main

import (
	"fmt"
	"game_of_stones/gomoku"
	"game_of_stones/tree"
	"math/rand"
	"time"
)

type move = gomoku.Move

type engine struct {
	title    string
	game     *gomoku.Gomoku
	tree     *tree.Tree[gomoku.Move, int16]
	duration time.Duration
}

func newEngine(title string) *engine {
	maxPlaces, maxMoves, expFactor, duration := parseTitle(title)
	aGame := gomoku.NewGame(maxPlaces)
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

	return places
}
