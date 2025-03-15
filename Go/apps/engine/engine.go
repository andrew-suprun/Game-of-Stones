package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"time"

	"game_of_stones/common"
	"game_of_stones/game"
	"game_of_stones/tree"
)

var logFileName = flag.String("log", "", "log file name")
var logFile *os.File

func main() {
	flag.Parse()
	if *logFileName != "" {
		var err error
		logFile, err = os.Create(*logFileName)
		if err != nil {
			fmt.Printf("Failed to open file %q: %#v\n", *logFileName, err)
		}
		defer logFile.Close()
	}
	reader := bufio.NewReader(os.Stdin)
	theGame := game.NewGame()
	theTree := tree.NewTree(theGame)
loop:
	for {
		line, err := reader.ReadString('\n')
		line = strings.TrimSpace(line)
		if err == io.EOF {
			return
		} else if err != nil {
			panic(err)
		}
		log("got %q\n", line)
		terms := strings.Split(line, " ")
		switch terms[0] {
		case "game-name":
			fmt.Printf("game-name %s\n", game.GameName)
		case "move":
			move, err := game.ParseMove(terms[1])
			if err != nil {
				panic(err)
			}
			theTree.CommitMove(move)
			log("%s", theGame)
		case "undo":
			theTree.Reset()
			log("%s", theGame)
		case "respond":
			millis, err := strconv.ParseInt(terms[1], 10, 64)
			if err != nil {
				panic(err)
			}
			timestamp := time.Now()
			maxDuration := time.Duration(millis) * time.Millisecond
			sims := 0
			for {
				dec, done := theTree.Expand()
				if done || dec != common.NoDecision || time.Since(timestamp) > maxDuration {
					break
				}
				sims++
			}
			move := theTree.BestMove()
			theTree.CommitMove(move)
			decision := theGame.Decision().String()
			fmt.Printf("move %s %s\n", move, decision)
			log("move %s %s %d\n", move, decision, sims)
			log("%s\n", theGame)
		case "stop":
			break loop
		}
	}
}

func log(format string, args ...any) {
	if logFile != nil {
		logFile.WriteString(fmt.Sprintf(format, args...))
	}
}
