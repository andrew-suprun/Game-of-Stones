package main

import (
	"bufio"
	"fmt"
	"game_of_stones/board"
	"game_of_stones/gomoku"
	"game_of_stones/tree"
	"game_of_stones/turn"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const usage = "Select color of your stones: gomoku [black|white]"
const maxSims = 10_000_000

func main() {
	// TODO: make maxMoves and expFactor runtime parameters
	maxMoves := 22
	expFactor := float64(100)

	var humanPlayer turn.Turn
	var humanStone rune
	var humanStoneSelected rune
	var engineStone rune
	var engineStoneSelected rune
	var game *gomoku.Gomoku
	var searchTree *tree.Tree[gomoku.Move]
	var event string
	var move string
	currentTurn := turn.Second
	running := false
	sims := 0
	events := make(chan string, 1)
	played := map[string]rune{}

	_, _, _ = humanStone, engineStone, currentTurn

	if len(os.Args) == 2 {
		switch strings.ToLower(os.Args[1]) {
		case "black":
			humanPlayer = turn.First
			humanStone = 'b'
			humanStoneSelected = 'B'
			engineStone = 'w'
			engineStoneSelected = 'W'
		case "white":
			humanPlayer = turn.Second
			humanStone = 'w'
			humanStoneSelected = 'W'
			engineStone = 'w'
			engineStoneSelected = 'W'
		default:
			fmt.Println(usage)
			return
		}
	} else {
		fmt.Println(usage)
		return
	}
	uiPath := filepath.Join(filepath.Dir(os.Args[0]), "ui")
	fmt.Println(uiPath)
	uiCmd := exec.Command(uiPath)
	writer, err := uiCmd.StdinPipe()
	if err != nil {
		panic(err)
	}
	reader, err := uiCmd.StdoutPipe()
	if err != nil {
		panic(err)
	}
	err = uiCmd.Start()
	if err != nil {
		panic(err)
	}
	defer uiCmd.Wait()

	go readInput(reader, events)

	for {
		if !running {
			running = true
			game = gomoku.NewGame(maxMoves)
			searchTree = tree.NewTree(game, maxMoves, expFactor)
			fmt.Fprintf(writer, "start\n")
			fmt.Fprintf(writer, "set j10 %c\n", humanStone)
			move, _ := game.ParseMove("j10")
			searchTree.CommitMove(move)
			played["j10"] = humanStone

			if humanPlayer == turn.First {
				moveStr := firstWhiteMove()
				fmt.Fprintf(writer, "set %s %c\n", moveStr, engineStoneSelected)
				move, _ := game.ParseMove(moveStr)
				searchTree.CommitMove(move)
				played[moveStr] = engineStoneSelected
				currentTurn = turn.First
			}
		}

		if event == "" {
			select {
			case event = <-events:
			default:
			}
		}

		if event != "" {
			fmt.Printf("event %q\n", event)
			fmt.Printf("sims %d\n", sims)
			if strings.HasPrefix(event, "error: ") {
				fmt.Println(event)
				os.Exit(1)
			} else if strings.HasPrefix(event, "info: ") {
				fmt.Println(event)
			} else if strings.HasPrefix(event, "click: ") {
				move = event[7:]
				fmt.Fprintf(writer, "set %s %c\n", move, humanStoneSelected)
				played[move] = humanStoneSelected
			} else if strings.HasPrefix(event, "key: ") {
				for move, stone := range played {
					switch stone {
					case 'B':
						fmt.Fprintf(writer, "set %s b\n", move)
					case 'W':
						fmt.Fprintf(writer, "set %s w\n", move)
					}
				}
				toPlay, err := game.ParseMove(move)
				if err != nil {
					panic(err)
				}
				searchTree.CommitMove(toPlay)
				played[move] = humanStone
				fmt.Fprintf(writer, "set %s %c\n", move, humanStone)

				// TODO Better respone timing
				engineMove, _ := searchTree.BestMove()
				fmt.Println("engine move", engineMove)
				searchTree.CommitMove(engineMove)
				fmt.Fprintf(writer, "set %v %c\n", engineMove, engineStoneSelected)
				played[engineMove.String()] = engineStoneSelected
			}
			event = ""
		}

		if sims < maxSims {
			_, sims = searchTree.Expand()
		} else {
			fmt.Println("reading event")
			event = <-events
			fmt.Println("read event")
		}

		// select

	}
}

func firstWhiteMove() string {
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+8+'a', board.Size-8-j))
			}
		}
	}

	return places[rand.Intn(8)]
}

func readInput(ioReader io.Reader, events chan string) {
	fmt.Println("start reader")
	reader := bufio.NewReader(ioReader)
	for {
		text, err := reader.ReadString('\n')
		fmt.Println("read", text)
		if err != nil {
			panic(err)
		}
		events <- strings.TrimSpace(text)
	}
}
