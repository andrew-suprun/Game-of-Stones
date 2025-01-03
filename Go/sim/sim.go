package main

import (
	"errors"
	"fmt"
	"game_of_stones/connect6"
	"game_of_stones/tree"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"
)

func main() {
	var a, b string
	for _, arg := range os.Args[1:] {
		parts := strings.Split(arg, "=")
		if len(parts) != 2 {
			continue
		}
		if parts[0] == "-a" {
			a = parts[1]
		}
		if parts[0] == "-b" {
			b = parts[1]
		}
	}
	if a == "" || b == "" {
		fmt.Println("required params: -a=maxPlaces,maxMoves,expFactor -b=maxPlaces,maxMoves,expFactor")
		return
	}

	winners := map[string]int{}

	for range 10 {
		moves := moves()
		winner, err := sim(a, b, moves)
		if err != nil {
			fmt.Println("required params: -a=maxPlaces,maxMoves,expFactor -b=maxPlaces,maxMoves,expFactor")
		}
		fmt.Println("winner.1", winner)
		winners[winner] += 1
		fmt.Println(winners)
		fmt.Println()
		winner, _ = sim(b, a, moves)
		fmt.Println("winner.2", winner)
		winners[winner] += 1
		fmt.Println(winners)
		fmt.Println()
	}
}

type engine struct {
	title    string
	game     *connect6.Connect6
	tree     *tree.Tree[*connect6.Connect6, connect6.Move, float32]
	duration time.Duration
}

func sim(a, b string, moves []string) (string, error) {
	engines := [2]engine{}
	maxPlaces, maxMoves, expFactor, duration, err := parseTitle(a)
	if err != nil {
		return "", err
	}
	aGame := connect6.NewGame(maxPlaces)
	aTree := tree.NewTree(aGame, maxMoves, expFactor)
	engines[0] = engine{
		title:    a,
		game:     aGame,
		tree:     aTree,
		duration: time.Duration(duration) * time.Millisecond,
	}

	maxPlaces, maxMoves, expFactor, duration, err = parseTitle(b)
	if err != nil {
		return "", err
	}
	bGame := connect6.NewGame(maxPlaces)
	bTree := tree.NewTree(bGame, maxMoves, expFactor)
	engines[1] = engine{
		title:    b,
		game:     bGame,
		tree:     bTree,
		duration: time.Duration(duration) * time.Millisecond,
	}

	m1, _ := aGame.ParseMove(moves[0])
	m2, _ := aGame.ParseMove(moves[1])
	m3, _ := aGame.ParseMove(moves[2])
	aTree.CommitMove(m1)
	aTree.CommitMove(m2)
	aTree.CommitMove(m3)
	bTree.CommitMove(m1)
	bTree.CommitMove(m2)
	bTree.CommitMove(m3)
	fmt.Println(aGame)
	for i := 1; ; i++ {
		var bestMove connect6.Move
		var s int
		_ = s
		start := time.Now()
		for time.Since(start) < engines[0].duration {
			m, _ := engines[0].tree.Expand()
			if m.IsDecisive() {
				break
			}
		}
		bestMove, s = engines[0].tree.BestMove()
		fmt.Printf("%s: Move %d %#v s: %d\n", engines[0].title, i, bestMove, s)
		if bestMove.IsTerminal() {
			return engines[0].title, nil
		}
		engines[0].tree.CommitMove(bestMove)
		engines[1].tree.CommitMove(bestMove)
		fmt.Println(engines[0].game)
		engines[0], engines[1] = engines[1], engines[0]
	}
}

func parseTitle(title string) (int, int, float64, int, error) {
	params := strings.Split(title, ",")
	if len(params) != 4 {
		return 0, 0, 0, 0, errors.New("title must be int,int,float,int")
	}
	maxPlaces, _ := strconv.Atoi(params[0])
	maxMoves, _ := strconv.Atoi(params[1])
	expFactor, _ := strconv.ParseFloat(params[2], 64)
	duration, _ := strconv.Atoi(params[3])
	return maxPlaces, maxMoves, expFactor, duration, nil
}

func moves() []string {
	// rnd := rand.New(rand.NewSource(time.Now().UnixNano()))
	rnd := rand.New(rand.NewSource(1))
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
