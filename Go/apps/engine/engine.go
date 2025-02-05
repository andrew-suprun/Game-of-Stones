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
		terms := strings.Split(line, " ")
		switch terms[0] {
		case "game-name":
			fmt.Println(game.GameName)
		case "move":
			move, err := game.ParseMove(terms[1])
			if err != nil {
				panic(err)
			}
			theTree.CommitMove(move)
			log("got %q", line)
			log("%s", theGame)
		case "respond":
			millis, err := strconv.ParseInt(terms[1], 10, 64)
			if err != nil {
				panic(err)
			}
			timestamp := time.Now()
			maxDuration := time.Duration(millis) * time.Millisecond
			for {
				dec, done := theTree.Expand()
				if done || dec != common.NoDecision || time.Since(timestamp) > maxDuration {
					log("forced response %v; decision %v time %v\n", done, dec, time.Since(timestamp))
					log("moves:\n%s\n", theTree.AvailableMoves())
					break
				}
			}
			move := theTree.BestMove()
			theTree.CommitMove(move)
			fmt.Printf("move %s\n", move)
			log("move %s\n", move)
			log("%s", theGame)
		case "decision":
			fmt.Printf("decision %s\n", theGame.Decision())
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
