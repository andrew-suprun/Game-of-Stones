package main

import (
	"bufio"
	"fmt"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"game_of_stones/game"
)

type Cmd struct {
	name   string
	player string
	cmd    *exec.Cmd
	in     *bufio.Reader
	out    io.Writer
}

type state struct {
	gameName     string
	openingMoves []game.Move
	millis       int64
	running      bool
	turn         int
	rnd          *rand.Rand
}

type stones int

const (
	blackStones stones = iota
	whiteStones
	ui
)

var stats = map[string]int{}

func main() {
	if len(os.Args) != 4 {
		fmt.Fprintln(os.Stderr, os.Args)
		fmt.Fprintln(os.Stderr, os.Args)
		panic("Expected 3 arguments: <millis> <engine1> engine2>.")
	}
	logChan := make(chan string, 1)
	go logPrinter(logChan)

	ui := startEngine("ui", logChan, "ui")
	uiChan := make(chan []string)
	go wait(ui)

	for range 10 {
		seed := time.Now().UnixNano()
		fmt.Fprintln(os.Stderr, "new openning 1")
		playOpening(os.Args[2], os.Args[3], ui, uiChan, logChan, seed)
		fmt.Fprintln(os.Stderr, "new openning 2")
		playOpening(os.Args[3], os.Args[2], ui, uiChan, logChan, seed)
	}
}

func playOpening(blackProc, whiteProc string, ui *Cmd, uiChan chan []string, logChan chan string, seed int64) {
	millis, err := strconv.ParseInt(os.Args[1], 10, 64)
	if err != nil {
		panic(err)
	}

	black := startEngine(blackProc, logChan, "X")
	gameNameX := black.call("game-name", "game-name")[0]
	white := startEngine(whiteProc, logChan, "O")
	gameNameO := white.call("game-name", "game-name")[0]
	if gameNameX != gameNameO {
		fmt.Fprintf(os.Stderr, "Inconsistent games: %s vs. %s.\n", gameNameX, gameNameO)
		os.Exit(1)
	}
	if gameNameX != "gomoku" && gameNameX != "connect6" {
		fmt.Fprintf(os.Stderr, "The game-name parameter is %q. Must be either  of \"gomoku\" or \"connect6\".\n", gameNameX)
		os.Exit(1)
	}

	ui.send("game-name %s", gameNameX)
	openingMoves := []game.Move(nil)
	rnd := rand.New(rand.NewSource(int64(seed)))
	if gameNameX == "gomoku" {
		openingMoves = selectGomokuOpeningMoves(rnd)
	} else {
		openingMoves = selectConnect6OpeningMoves(rnd)
	}

	for _, move := range openingMoves {
		black.send("move %s", move)
		white.send("move %s", move)
		ui.call("decision", "move %s", move)
	}

	if len(openingMoves)%2 == 1 {
		move := white.call("move", "respond %d", millis)[0]
		black.send("move %s", move)
		ui.call("decision", "move %s", move)
	}

	for {
		move := black.call("move", "respond %d", millis)[0]
		decision := ui.call("decision", "move %s", move)[0]
		if decision != "no-decision" {
			stats[black.player]++
			break
		}
		white.send("move %s", move)
		move = white.call("move", "respond %d", millis)[0]
		decision = ui.call("decision", "move %s", move)[0]
		if decision != "no-decision" {
			stats[white.player]++
			break
		}
		black.send("move %s", move)
	}

	fmt.Println("stats", stats)
	<-time.After(2 * time.Second)
	ui.send("clear")
}

func selectGomokuOpeningMoves(rnd *rand.Rand) []game.Move {
	openingMoves := []game.Move{{P1: game.Place{X: game.Size / 2, Y: game.Size / 2}, P2: game.Place{X: game.Size / 2, Y: game.Size / 2}}}
	random := randomPlaces()
	for range 4 {
		r := rnd.Intn(len(random))
		place := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		openingMoves = append(openingMoves, game.Move{P1: place, P2: place})
	}
	return openingMoves
}

func selectConnect6OpeningMoves(rnd *rand.Rand) []game.Move {
	openingMoves := []game.Move{{
		P1: game.Place{X: game.Size / 2, Y: game.Size / 2},
		P2: game.Place{X: game.Size / 2, Y: game.Size / 2}}}
	random := randomPlaces()
	for range 2 {
		r := rnd.Intn(len(random))
		place1 := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		r = rnd.Intn(len(random))
		place2 := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		openingMoves = append(openingMoves, game.Move{P1: place1, P2: place2})
	}
	return openingMoves
}

func randomPlaces() []game.Place {
	random := []game.Place{}
	for j := range 5 {
		for i := range 5 {
			if i != 2 || j != 2 {
				random = append(random, game.Place{X: int8(game.Size/2 - 2 + i), Y: int8(game.Size/2 - 2 + j)})
			}
		}
	}
	return random
}

func (cmd *Cmd) call(expected, format string, args ...any) []string {
	cmd.send(format, args...)
	for {
		text, _ := cmd.in.ReadString('\n')
		text = strings.TrimSpace(text)
		fields := strings.Fields(text)
		if fields[0] == expected {
			fmt.Fprintf(os.Stderr, "<- %s-%s: %q\n", cmd.name, cmd.player, text)
			return fields[1:]
		}
	}

}

func (cmd *Cmd) send(format string, args ...any) {
	text := fmt.Sprintf(format, args...)
	fmt.Fprintln(cmd.out, text+"\n")
	fmt.Fprintf(os.Stderr, "-> %s-%s: %q\n", cmd.name, cmd.player, text)
}

func wait(cmd *Cmd) {
	cmd.cmd.Wait()
	os.Exit(0)
}

func startEngine(path string, logChan chan string, name string) *Cmd {
	path = filepath.Join(filepath.Dir(os.Args[0]), path)
	parts := strings.Split(path, " ")
	cmd := exec.Command(parts[0], parts[1:]...)
	var err error
	in, err := cmd.StdoutPipe()
	if err != nil {
		panic(err)
	}
	log, err := cmd.StderrPipe()
	if err != nil {
		panic(err)
	}
	go runLogger(bufio.NewReader(log), logChan, name)
	out, err := cmd.StdinPipe()
	if err != nil {
		panic(err)
	}
	err = cmd.Start()
	if err != nil {
		panic(err)
	}
	return &Cmd{name, parts[0], cmd, bufio.NewReader(in), out}
}

func runLogger(log *bufio.Reader, logChan chan string, name string) {
	for {
		line, err := log.ReadString('\n')
		if err == io.EOF {
			return
		}
		if err != nil {
			panic(err)
		}
		logChan <- name + ": " + line
	}
}

func logPrinter(logChan chan string) {
	for {
		line := <-logChan
		fmt.Fprint(os.Stderr, line)
	}
}
