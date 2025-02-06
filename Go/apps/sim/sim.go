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

	"game_of_stones/game"
)

type Cmd struct {
	name string
	cmd  *exec.Cmd
	in   *bufio.Reader
	out  io.Writer
}

type state struct {
	gameName     string
	nMove        int
	openingMoves []game.Move
	millis       int64
	running      bool
	rnd          *rand.Rand
}

type stones int

const (
	blackStones stones = iota
	whiteStones
)

func main() {
	if len(os.Args) != 4 {
		fmt.Println(os.Args)
		panic("Expected 3 arguments: <millis> <engine1> engine2>.")
	}
	logChan := make(chan string, 1)
	go logPrinter(logChan)

	ui := startEngine("ui", logChan, "Ui")
	go wait(ui)

	stats := map[string]int{}

	for i := range 10 {
		playOpening(os.Args[2], os.Args[3], ui, logChan, int64(i), stats)
		playOpening(os.Args[3], os.Args[2], ui, logChan, int64(i), stats)
	}
}

func playOpening(blackProc, whiteProc string, ui *Cmd, logChan chan string,
	seed int64, stats map[string]int) {
	millis, err := strconv.ParseInt(os.Args[1], 10, 64)
	if err != nil {
		panic(err)
	}

	black := startEngine(blackProc, logChan, "X")
	fmt.Fprintf(black.out, "game-name\n")
	blackChan := make(chan []string)
	go reader(black, blackChan)
	white := startEngine(whiteProc, logChan, "O")
	fmt.Fprintf(white.out, "game-name\n")
	whiteChan := make(chan []string)
	go reader(white, whiteChan)

	state := &state{rnd: rand.New(rand.NewSource(int64(seed))), millis: millis, running: true}

	for state.running {
		select {
		case event := <-blackChan:
			state.handleEvent(event, black, white, ui, blackStones)
		case event := <-whiteChan:
			state.handleEvent(event, white, black, ui, whiteStones)
		}
	}

	fmt.Println(stats)
	<-time.After(3 * time.Second)
	fmt.Fprintln(ui.out, "clear")
}

func (state *state) handleEvent(event []string, this, that, ui *Cmd, stones stones) {
	if len(event) < 2 {
		return
	}
	switch event[0] {
	case "game-name":
		if state.gameName == "" {
			state.gameName = event[1]
			ui.send("game-name %s", state.gameName)
		} else if state.gameName != event[1] {
			log.Fatalf("engings are playing different games: %q and %q",
				state.gameName, event[1])
		}
		if state.gameName == "gomoku" {
			state.selectGomokuOpeningMoves()
		} else if state.gameName == "connect6" {
			state.selectConnect6OpeningMoves()
		} else {
			log.Fatalf("Wrong game: %q choose either \"gomoku\" or \"connect6\"")
		}
		for _, move := range state.openingMoves {
			this.send("move %s", move)
			that.send("move %s", move)
			ui.send("move %s", move)
		}
		if len(state.openingMoves)%2 == 0 {
			this.send("respond %d", state.millis)
		} else {
			that.send("respond %d", state.millis)
		}
	case "move":
	case "decision":
	}
}

func reader(engine *Cmd, engineChan chan []string) {
	for {
		line, err := engine.in.ReadString('\n')
		if err != nil {
			panic(err)
		}
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
	return &Cmd{path, cmd, bufio.NewReader(in), out}
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
		line = strings.TrimSpace(line)
		fmt.Fprintln(os.Stderr, line)
	}
}
