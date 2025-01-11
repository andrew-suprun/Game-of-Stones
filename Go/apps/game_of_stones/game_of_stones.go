package main

import (
	"fmt"
	"game_of_stones/turn"
	"os"
	"strconv"
	"strings"
	"time"
)

const usage = `Usage: game_of_stones [params]
    game=[gomoku|connect6] (connect6)
    stones=[black|white] (black)
	max-moves=N (22)
	max-places=N (22)
	exp-factor=N (100)
	ms-per-move=N (250)
`

const (
	connect6Id = iota
	gomokuId
)

type gameOfStones struct {
	in, out chan string
}

var (
	gameId            int
	humanPlayerStones turn.Turn
	maxSims           = 10_000_000
	maxMoves          = 22
	expFactor         = float64(100)
	msPerMove         = 250 * time.Millisecond
	games             = [2]gameOfStones{}
)

func main() {
	parseArgs()

	chIn1 := make(chan string, 1)
	chOut1 := make(chan string, 1)
	// chIn2 := make(chan string, 1)
	// chOut2 := make(chan string, 1)
	// go newHumanPlayer(gameId, turn.First, chOut1, chIn1)
	// go newHumanPlayer(gameId, turn.Second, chOut2, chIn2)
	// running := true
	// for running {
	// 	select {
	// 	case event := <-chIn1:
	// 		handleEvent(event, chOut2, "[1]")
	// 	case event := <-chIn2:
	// 		handleEvent(event, chOut1, "[2]")
	// 	}
	// }

	// DEBUG
	go newHumanPlayer(gameId, turn.First, chOut1, chIn1)
	running := true
	n := 1
	for running {
		select {
		case event := <-chIn1:
			if strings.HasPrefix(event, "error: ") || strings.HasPrefix(event, "info: ") {
				fmt.Println(event)
				continue
			}
			fmt.Printf("<< read: %q\n", event)
			switch n {
			case 1:
				chOut1 <- "i9-i11"
			case 2:
				chOut1 <- "g10-k10"
			case 3:
				chOut1 <- "j8-j12"
			}
			n++
		}
	}
}

func parseArgs() {
	for _, arg := range os.Args {
		if strings.HasPrefix(arg, "game=") {
			if strings.ToLower(arg[5:]) == "connect6" {
				gameId = connect6Id
			} else if strings.ToLower(arg[5:]) == "gomoku" {
				gameId = gomokuId
			} else {
				fmt.Println("Invalid game parameter.")
				fmt.Print(usage)
				os.Exit(1)
			}
		} else if strings.HasPrefix(arg, "stones=") {
			if strings.ToLower(arg[7:]) == "black" {
				humanPlayerStones = turn.First
			} else if strings.ToLower(arg[7:]) == "white" {
				humanPlayerStones = turn.Second
			} else {
				fmt.Println("Invalid stones parameter.")
				fmt.Print(usage)
				os.Exit(1)
			}
		} else if strings.HasPrefix(arg, "ms-per-move=") {
			parsed, err := strconv.ParseInt(arg[12:], 10, 64)
			if err != nil {
				fmt.Println("Invalid ms-per-move parameter.")
				fmt.Print(usage)
				os.Exit(1)
			}
			msPerMove = time.Duration(parsed) * time.Millisecond

		} else if strings.HasPrefix(arg, "exp-factor=") {
			var err error
			expFactor, err = strconv.ParseFloat(arg[11:], 64)
			if err != nil {
				fmt.Println("Invalid exp-factor parameter.")
				fmt.Print(usage)
				os.Exit(1)
			}
		} else if strings.HasPrefix(arg, "max-moves=") {
			parsed, err := strconv.ParseInt(arg[10:], 10, 64)
			if err != nil {
				fmt.Println("Invalid ms-per-move parameter.")
				fmt.Print(usage)
				os.Exit(1)
			}
			maxMoves = int(parsed)
		}
	}
}

func handleEvent(event string, out chan string, debug string) bool {
	fmt.Printf("read from %s: %q\n", debug, event)
	if event == "stop" {
		fmt.Println("### stopping")
		out <- "stop"
		return false
	}
	fmt.Printf("### sending %q\n", event)
	out <- event
	return true
}
