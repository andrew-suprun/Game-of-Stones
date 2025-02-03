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

var maxPlaces = flag.Int("places", 20, "number of places to consider")
var maxMoves = flag.Int("moves", 64, "number of moves to consider")
var explorationCoeff = flag.Float64("C", 100, "exploration coeffitient")
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
	theGame := game.NewGame(*maxPlaces)
	theTree := tree.NewTree(theGame, *maxMoves, *explorationCoeff)
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
		case "game-kind":
			fmt.Println(game.GameName)
		case "game-name":
			intValues := theGame.StoneValues()
			strValues := make([]string, len(intValues))
			for i := range intValues {
				strValues[i] = fmt.Sprintf("%d", intValues[i])
			}
			fmt.Println(strings.Join(strValues, ","))
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
			expanstions := 0
			for {
				dec := theTree.Expand()
				expanstions++
				duration := time.Since(timestamp)
				if dec != common.NoDecision || duration > maxDuration {
					log("expanded: %s; value %d; expansions %d; time %v\n", dec, theTree.Value(), expanstions, duration)
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
