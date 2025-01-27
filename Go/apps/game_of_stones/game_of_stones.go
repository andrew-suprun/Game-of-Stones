package main

import (
	"fmt"
	"os"
	"strings"

	. "game_of_stones/common"
	"game_of_stones/game"
)

const usage = `Usage: game_of_stones [params]
    -game=[gomoku|connect6] (gomoku)
    -stones=[black|white] (black)
`

const (
	gomokuId game.GameName = iota
	connect6Id
)

var (
	gameId             = game.Gomoku
	humanPlayerStones  = First
	enginePlayerStones = Second
)

func main() {
	parseArgs()

	chIn1 := make(chan string, 1)
	chOut1 := make(chan string, 1)
	chIn2 := make(chan string, 1)
	chOut2 := make(chan string, 1)

	go runHumanPlayer(gameId, humanPlayerStones, chOut1, chIn1)
	go runEngine(gameId, enginePlayerStones, chOut2, chIn2)
	running := true
	for running {
		run := true
		select {
		case event := <-chIn1:
			run = handleEvent(event, chOut2)
		case event := <-chIn2:
			run = handleEvent(event, chOut1)
		}
		if !run {
			close(chIn1)
			close(chIn2)
			break
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
				// default
			} else if strings.ToLower(arg[8:]) == "white" {
				humanPlayerStones = Second
				enginePlayerStones = First
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
		return true
	}
	if event == "stop" {
		out <- "stop"
		return false
	}
	out <- event
	return true
}
