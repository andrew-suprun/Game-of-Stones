package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"game_of_stones/common"
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
		fmt.Println(os.Args)
		panic("Expected 3 arguments: <millis> <engine1> engine2>.")
	}
	logChan := make(chan string, 1)
	go logPrinter(logChan)

	ui := startEngine("ui", logChan, "Ui")
	go wait(ui)

	for range 10 {
		seed := time.Now().UnixNano()
		playOpening(os.Args[2], os.Args[3], ui, logChan, seed)
		playOpening(os.Args[3], os.Args[2], ui, logChan, seed)
	}
}

func playOpening(blackProc, whiteProc string, ui *Cmd, logChan chan string, seed int64) {
	millis, err := strconv.ParseInt(os.Args[1], 10, 64)
	if err != nil {
		panic(err)
	}

	black := startEngine(blackProc, logChan, "X")
	black.send("game-name")
	blackChan := make(chan []string)
	go reader(black, blackChan)
	white := startEngine(whiteProc, logChan, "O")
	white.send("game-name")
	whiteChan := make(chan []string)
	go reader(white, whiteChan)

	state := &state{rnd: rand.New(rand.NewSource(int64(seed))), millis: millis, running: true}

	for state.running {
		select {
		case event := <-blackChan:
			state.handleEvent(event, black, white, ui, black.name, black.player)
		case event := <-whiteChan:
			state.handleEvent(event, white, black, ui, white.name, white.player)
		}
	}

	fmt.Fprintln(os.Stderr, stats)
	<-time.After(3 * time.Second)
	fmt.Fprintln(ui.out, "clear")
}

func (state *state) handleEvent(event []string, this, that, ui *Cmd, name, player string) {
	if len(event) < 2 {
		return
	}
	// fmt.Fprintf(os.Stderr, "> received from %s-%s: %v\n", player, name, event)
	switch event[0] {
	case "game-name":

		if state.gameName == "" {
			state.gameName = event[1]
			ui.send("game-name %s", state.gameName)
			return
		} else if state.gameName != event[1] {
			log.Fatalf("engings are playing different games: %q and %q",
				state.gameName, event[1])
		}
		if state.gameName == "gomoku" {
			state.selectGomokuOpeningMoves()
		} else if state.gameName == "connect6" {
			state.selectConnect6OpeningMoves()
		} else {
			log.Fatalf("Wrong game: %q choose either \"gomoku\" or \"connect6\"", state.gameName)
		}
		for _, move := range state.openingMoves {
			this.send("move %s", move)
			that.send("move %s", move)
			ui.send("move %s", move)
		}
		if len(state.openingMoves)%2 == 0 && this.name == "X" ||
			len(state.openingMoves)%2 == 1 && this.name == "O" {

			this.send("respond %d", state.millis)
		} else {
			that.send("respond %d", state.millis)
		}
	case "move":
		ui.send("move %s", event[1])
		that.send("move %s", event[1])
		this.send("decision")
	case "decision":
		switch event[1] {
		case common.NoDecision.String():
			that.send("respond %d", state.millis)
		case common.Draw.String():
			state.running = false
		default:
			stats[this.player]++
			state.running = false
			this.send("stop")
			that.send("stop")
		}
	}
}

func reader(engine *Cmd, engineChan chan []string) {
	for {
		line, _ := engine.in.ReadString('\n')
		engineChan <- strings.Fields(line)
	}
}

func (state *state) selectGomokuOpeningMoves() {
	state.openingMoves = []game.Move{{P1: game.Place{X: game.Size / 2, Y: game.Size / 2}, P2: game.Place{X: game.Size / 2, Y: game.Size / 2}}}
	random := randomPlaces()
	for range 4 {
		r := state.rnd.Intn(len(random))
		place := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		state.openingMoves = append(state.openingMoves, game.Move{P1: place, P2: place})
	}
}

func (state *state) selectConnect6OpeningMoves() {
	state.openingMoves = []game.Move{{
		P1: game.Place{X: game.Size / 2, Y: game.Size / 2},
		P2: game.Place{X: game.Size / 2, Y: game.Size / 2}}}
	random := randomPlaces()
	for range 2 {
		r := state.rnd.Intn(len(random))
		place1 := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		r = state.rnd.Intn(len(random))
		place2 := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		state.openingMoves = append(state.openingMoves, game.Move{P1: place1, P2: place2})
	}
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

func (cmd *Cmd) send(format string, args ...any) {
	fmt.Fprintf(cmd.out, "%s\n", fmt.Sprintf(format, args...))
	// fmt.Fprintf(os.Stderr, "> sent to %s: %q\n", cmd.player, fmt.Sprintf(format, args...))
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
