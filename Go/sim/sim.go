package main

import (
	"fmt"
	"game_of_stones/common"
	"game_of_stones/game"
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
		fmt.Println("required params: -a=maxPlaces,maxMoves,expFactor,duration -b=maxPlaces,maxMoves,expFactor,duration")
		return
	}

	winners := map[string]int{}

	for range 10 {
		moves := moves()
		winner := sim(a, b, moves)
		fmt.Println("winner.1", winner)
		winners[winner] += 1
		fmt.Println(winners)
		fmt.Println()
		winner = sim(b, a, moves)
		fmt.Println("winner.2", winner)
		winners[winner] += 1
		fmt.Println(winners)
		fmt.Println()
	}
}

func sim(a, b string, moves []string) string {
	engines := [2]*engine{
		newEngine(a),
		newEngine(b),
	}

	for _, moveStr := range moves {
		move, _ := game.ParseMove(moveStr)
		engines[0].tree.CommitMove(move)
		engines[1].tree.CommitMove(move)
	}

	fmt.Println(engines[0].game)

	for i := 1; ; i++ {
		var bestMove move
		s := 0
		undec := 0
		dec := common.NoDecision
		start := time.Now()
		for time.Since(start) < engines[0].duration {
			s += 1
			dec, undec = engines[0].tree.Expand()
			if dec != common.NoDecision || undec < 2 {
				break
			}
		}
		bestMove = engines[0].tree.BestMove()
		fmt.Printf("%v %s: Move %3d %v s: %7d d: %v undec: %d\n", time.Since(start), engines[0].title, i, bestMove, s, dec, undec)
		engines[0].tree.CommitMove(bestMove)
		engines[1].tree.CommitMove(bestMove)

		fmt.Println(engines[0].game)

		dec = engines[0].game.Decision()
		if dec != common.NoDecision {
			if dec == common.Draw {
				return "Draw"
			}
			return engines[0].title
		}

		engines[0], engines[1] = engines[1], engines[0]
	}
}

func parseTitle(title string) (int, int, float64, int) {
	params := strings.Split(title, ",")
	if len(params) != 4 {
		panic("parseTitle")
	}
	maxPlaces, _ := strconv.Atoi(params[0])
	maxMoves, _ := strconv.Atoi(params[1])
	expFactor, _ := strconv.ParseFloat(params[2], 64)
	duration, _ := strconv.Atoi(params[3])
	return maxPlaces, maxMoves, expFactor, duration
}

type move = game.Move

type engine struct {
	title    string
	game     *game.Game
	tree     *tree.Tree[game.Move]
	duration time.Duration
}

func newEngine(title string) *engine {
	maxPlaces, maxMoves, expFactor, duration := parseTitle(title)
	aGame := game.NewGame(maxPlaces)
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
		place := fmt.Sprintf("%c%d", rnd.Intn(9)+game.Size/2-5+'a', rnd.Intn(9)+game.Size/2-4)
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
