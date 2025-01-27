package main

import (
	"bufio"
	"fmt"
	"game_of_stones/game"
	"game_of_stones/tree"
	"io"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"
)

const usage = `Usage: game_of_stones [params]
    -game=[gomoku|connect6] (gomoku)
`

var gameId = game.Gomoku
var name string

func main() {
	parseArgs()
	randomName()
	reader := bufio.NewReader(os.Stdin)
	theGame := game.NewGame(gameId, 22)
	theTree := tree.NewTree[game.Move](theGame, 64, 20)
loop:
	for {
		line, err := reader.ReadString('\n')
		line = strings.TrimSpace(line)
		log("got %q", line)
		if err == io.EOF {
			return
		} else if err != nil {
			panic(err)
		}
		terms := strings.Split(line, " ")
		switch terms[0] {
		case "game-name":
			switch gameId {
			case game.Gomoku:
				fmt.Println("gomoku")
			case game.Connect6:
				fmt.Println("connect6")
			}
		case "move":
			move, err := theGame.ParseMove(terms[1])
			if err != nil {
				panic(err)
			}
			theTree.CommitMove(move)
		case "respond":
			millis, err := strconv.ParseInt(terms[1], 10, 64)
			if err != nil {
				panic(err)
			}
			timestamp := time.Now()
			dur := time.Duration(millis) * time.Millisecond
			for {
				move, _ := theTree.Expand()
				if move.IsDecisive() || time.Since(timestamp) > dur {
					move = theTree.BestMove()
					theTree.CommitMove(move)
					fmt.Printf("move %s\n", move)
					log("move %s\n", move)
					break
				}
			}
		case "stop":
			break loop
		}
	}
}

func parseArgs() {
	for _, arg := range os.Args {
		if strings.HasPrefix(arg, "-game=") {
			if strings.ToLower(arg[6:]) == "connect6" {
				gameId = game.Connect6
			} else if strings.ToLower(arg[6:]) == "gomoku" {
				gameId = game.Gomoku
			} else {
				fmt.Println("Invalid game parameter.")
				fmt.Print(usage)
				os.Exit(1)
			}
		}
	}
}

func randomName() {
	rnd := rand.New(rand.NewSource(time.Now().UnixNano()))
	name = fmt.Sprintf("%c> ", 'A'+rnd.Intn(26))
}

func log(format string, args ...any) {
	line := fmt.Sprintf(format, args...)
	line = strings.TrimSpace(line)
	fmt.Fprintln(os.Stderr, name+line)
}
