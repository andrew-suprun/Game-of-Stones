package main

import (
	"fmt"
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

func sim(a, b string, moves []string) (string, error) {
	engines := [2]*engine{
		newEngine(a),
		newEngine(b),
	}

	for _, moveStr := range moves {
		move, _ := engines[0].game.ParseMove(moveStr)
		engines[0].tree.CommitMove(move)
		engines[1].tree.CommitMove(move)
	}

	fmt.Println(engines[0].game)

	for i := 1; ; i++ {
		var bestMove move
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
			if bestMove.Value() == 0 {
				return "Draw", nil
			}
			return engines[0].title, nil
		}
		engines[0].tree.CommitMove(bestMove)
		engines[1].tree.CommitMove(bestMove)
		fmt.Println(engines[0].game)
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
