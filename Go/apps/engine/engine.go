package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"

	"game_of_stones/common"
	"game_of_stones/game"
	"game_of_stones/tree"
)

var name string

func main() {
	flag.Parse()
	randomName()
	reader := bufio.NewReader(os.Stdin)
	theGame := game.NewGame(22)
	theTree := tree.NewTree(theGame, 64, 20)
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
			fmt.Println(game.GameName)
		case "move":
			move, err := game.ParseMove(terms[1])
			if err != nil {
				panic(err)
			}
			theTree.CommitMove(move)
			log("committed move %s\n", move)
		case "respond":
			millis, err := strconv.ParseInt(terms[1], 10, 64)
			if err != nil {
				panic(err)
			}
			timestamp := time.Now()
			dur := time.Duration(millis) * time.Millisecond
			for {
				dec, undec := theTree.Expand()
				if dec != common.NoDecision || undec < 2 || time.Since(timestamp) > dur {
					break
				}
			}
			move := theTree.BestMove()
			theTree.CommitMove(move)
			dec, x, y, dx, dy := theGame.Decision()
			if dec != common.NoDecision {
				fmt.Printf("move %s %v %d %d %d %d\n", move, dec, x, y, dx, dy)
				return
			} else {
				fmt.Printf("move %s\n", move)
			}
		case "stop":
			break loop
		}
	}
}

var maxPlaces = flag.Int("places", 20, "number of places to consider")
var maxMoves = flag.Int("moves", 64, "number of moves to consider")
var explorationCoeff = flag.Float64("C", 100, "exploration coeffitient")

func randomName() {
	rnd := rand.New(rand.NewSource(time.Now().UnixNano()))
	name = fmt.Sprintf("%c%c> ", 'A'+rnd.Intn(26), 'a'+rnd.Intn(26))
}

func log(format string, args ...any) {
	line := fmt.Sprintf(format, args...)
	line = strings.TrimSpace(line)
	fmt.Fprintln(os.Stderr, name+line)
}
