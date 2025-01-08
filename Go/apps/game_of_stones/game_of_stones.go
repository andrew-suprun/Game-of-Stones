package main

import (
	"bufio"
	"fmt"
	"game_of_stones/board"
	"game_of_stones/connect6"
	"game_of_stones/gomoku"
	"game_of_stones/tree"
	"game_of_stones/turn"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const usage = `Usage: game_of_stones [params]
    game=[gomoku|connect6] (connect6)
    stones=[black|white] (black)
	max-moves=N (22)
	exp-factor=N (100)
	ms-per-move=N (250)
`

const (
	connect6Id = iota
	gomokuId
)

var (
	gameId              int
	humanPlayer         turn.Turn
	maxSims             = 10_000_000
	maxMoves            = 22
	expFactor           = float64(100)
	msPerMove           = 250 * time.Millisecond
	humanStone          = 'b'
	humanStoneSelected  = 'B'
	engineStone         = 'w'
	engineStoneSelected = 'W'
	gomokuGame          *gomoku.Gomoku
	connect6Game        *connect6.Connect6
	gomokuTree          *tree.Tree[gomoku.Move]
	connect6Tree        *tree.Tree[connect6.Move]
	events              = make(chan string, 1)
	played              = map[string]rune{}
	currentTurn         = turn.Second
	writer              io.Writer
)

func main() {
	var event string
	var move string

	parseArgs()
	startGame()
	sims := 0
	for {
		if event == "" {
			select {
			case event = <-events:
			default:
			}
		}

		if event != "" {
			fmt.Printf("event %q\n", event)
			fmt.Printf("sims %d\n", sims)
			if event == "stop" {
				os.Exit(0)
			}
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
				if gameId == connect6Id {
					toPlay, err := connect6Game.ParseMove(move)
					if err != nil {
						panic(err)
					}
					connect6Tree.CommitMove(toPlay)
					played[move] = humanStone
					places := strings.Split(move, "-")
					fmt.Fprintf(writer, "set %s %c\n", places[0], humanStone)
					fmt.Fprintf(writer, "set %s %c\n", places[1], humanStone)
				} else {
					toPlay, err := gomokuGame.ParseMove(move)
					if err != nil {
						panic(err)
					}
					gomokuTree.CommitMove(toPlay)
					played[move] = humanStone
					fmt.Fprintf(writer, "set %s %c\n", move, humanStone)
				}

			}

			// {
			// 	// TODO Better respone timing
			// 	engineMove, _ := gomokuTree.BestMove()
			// 	fmt.Println("engine move", engineMove)
			// 	gomokuTree.CommitMove(engineMove)
			// 	fmt.Fprintf(writer, "set %v %c\n", engineMove, engineStoneSelected)
			// 	played[engineMove.String()] = engineStoneSelected
			// 	event = ""
			// }
		}

		if sims < maxSims {
			if gameId == connect6Id {
				_, sims = connect6Tree.Expand()
			} else {
				_, sims = gomokuTree.Expand()
			}
		} else {
			fmt.Println("reading event")
			event = <-events
			fmt.Println("read event")
		}
	}
}

func firstWhiteConnect6Move() string {
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+8+'a', board.Size-8-j))
			}
		}
	}

	idx1 := rand.Intn(8)
	idx2 := idx1
	for idx1 == idx2 {
		idx2 = rand.Intn(8)
	}
	return places[idx1] + "-" + places[idx2]
}

func firstWhiteGomokuMove() string {
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
				humanPlayer = turn.First
				humanStone = 'b'
				humanStoneSelected = 'B'
				engineStone = 'w'
				engineStoneSelected = 'W'
			} else if strings.ToLower(arg[7:]) == "white" {
				humanPlayer = turn.Second
				humanStone = 'w'
				humanStoneSelected = 'W'
				engineStone = 'w'
				engineStoneSelected = 'W'
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

func startGame() {
	uiPath := filepath.Join(filepath.Dir(os.Args[0]), "ui")
	uiCmd := exec.Command(uiPath)
	var err error
	writer, err = uiCmd.StdinPipe()
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

	go readInput(reader)

	if gameId == connect6Id {
		connect6Game = connect6.NewGame(maxMoves)
		connect6Tree = tree.NewTree(connect6Game, maxMoves, expFactor)
		fmt.Fprintf(writer, "set j10 b\n")
		move, _ := connect6Game.ParseMove("j10-j10")
		connect6Tree.CommitMove(move)
		played["j10"] = 'b'
		if gameId == connect6Id {
			moveStr := firstWhiteConnect6Move()
			places := strings.Split(moveStr, "-")
			fmt.Println("places", places)
			fmt.Fprintf(writer, "set %s %c\n", places[0], engineStoneSelected)
			fmt.Fprintf(writer, "set %s %c\n", places[1], engineStoneSelected)
			fmt.Printf("set %s %c\n", places[0], engineStoneSelected)
			fmt.Printf("set %s %c\n", places[1], engineStoneSelected)
			move, _ := connect6Game.ParseMove(moveStr)
			connect6Tree.CommitMove(move)
			currentTurn = turn.First
		}
	} else {
		gomokuGame = gomoku.NewGame(maxMoves)
		gomokuTree = tree.NewTree(gomokuGame, maxMoves, expFactor)
		fmt.Fprintf(writer, "set j10 b\n")
		move, _ := gomokuGame.ParseMove("j10")
		gomokuTree.CommitMove(move)
		played["j10"] = 'b'
		if gameId == connect6Id {
			moveStr := firstWhiteGomokuMove()
			fmt.Fprintf(writer, "set %s %c\n", moveStr, engineStoneSelected)
			move, _ := gomokuGame.ParseMove(moveStr)
			gomokuTree.CommitMove(move)
			played[moveStr] = engineStoneSelected
			currentTurn = turn.First
		}
	}
}

func readInput(ioReader io.Reader) {
	fmt.Println("start reader")
	reader := bufio.NewReader(ioReader)
	for {
		text, err := reader.ReadString('\n')
		fmt.Println("read", text)
		if err == io.EOF {
			events <- "stop"
			return
		}
		if err != nil {
			panic(err)
		}
		events <- strings.TrimSpace(text)
	}
}
