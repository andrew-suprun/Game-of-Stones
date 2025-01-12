package main

import (
	"fmt"
	"game_of_stones/game"
	"game_of_stones/turn"
	"os"
	"strings"
	"time"
)

const usage = `Usage: game_of_stones [params]
    game=[gomoku|connect6] (connect6)
    stones=[black|white] (black)
`

const (
	gomokuId game.GameName = iota
	connect6Id
)

type gameOfStones struct {
	in, out chan string
}

const (
	maxSims   = 10_000_000
	maxMoves  = 22
	expFactor = float64(100)
	msPerMove = 250 * time.Millisecond
)

var (
	gameId            game.GameName
	humanPlayerStones turn.Turn
	games             = [2]gameOfStones{}
)

func main() {
	parseArgs()

	chIn1 := make(chan string, 1)
	chOut1 := make(chan string, 1)
	chIn2 := make(chan string, 1)
	chOut2 := make(chan string, 1)
	go newHumanPlayer(gameId, turn.First, chOut1, chIn1)
	go newEngine(gameId, turn.Second, chOut2, chIn2)
	running := true
	for running {
		select {
		case event := <-chIn1:
			handleEvent(event, chOut2)
		case event := <-chIn2:
			handleEvent(event, chOut1)
		}
	}
}

func parseArgs() {
	for _, arg := range os.Args {
		if strings.HasPrefix(arg, "-game=") {
			if strings.ToLower(arg[6:]) == "connect6" {
				gameId = connect6Id
			} else if strings.ToLower(arg[6:]) == "gomoku" {
				gameId = gomokuId
			} else {
				fmt.Println("Invalid game parameter.")
				fmt.Print(usage)
				os.Exit(1)
			}
		} else if strings.HasPrefix(arg, "-stones=") {
			if strings.ToLower(arg[8:]) == "black" {
				humanPlayerStones = turn.First
			} else if strings.ToLower(arg[8:]) == "white" {
				humanPlayerStones = turn.Second
			} else {
				fmt.Println("Invalid stones parameter.")
				fmt.Print(usage)
				os.Exit(1)
			}
		}
	}
}

func handleEvent(event string, out chan string) bool {
	if strings.HasPrefix(event, "info: ") || strings.HasPrefix(event, "error: ") {
		fmt.Println(event)
		return true
	}
	if event == "stop" {
		fmt.Println("### stopping")
		out <- "stop"
		return false
	}
	out <- event
	return true
}
