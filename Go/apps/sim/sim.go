package main

import (
	"bufio"
	"fmt"
	"game_of_stones/common"
	"game_of_stones/game"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type Cmd struct {
	name string
	cmd  *exec.Cmd
	in   *bufio.Reader
	out  io.Writer
}

func main() {
	if len(os.Args) != 3 {
		fmt.Println(os.Args)
		panic("Expected 2 arguments: <millis> <engine>")
	}
	logChan := make(chan string, 1)
	go logPrinter(logChan)

	ui := startEngine("ui", logChan, "Ui")
	go wait(ui)

	for {
		playOpening(os.Args[2], os.Args[2], ui, logChan)
	}
}

func playOpening(blackProc, whiteProc string, ui *Cmd, logChan chan string) {
	millis, err := strconv.ParseInt(os.Args[1], 10, 64)
	if err != nil {
		panic(err)
	}

	black := startEngine(blackProc, logChan, "X")
	white := startEngine(whiteProc, logChan, "O")
	// black := startEngine(blackProc+" -log=log-black.log", logChan, "X")
	// white := startEngine(whiteProc+" -log=log-white.log", logChan, "O")
	fmt.Fprintf(black.out, "game-name\n")
	name, _ := black.in.ReadString('\n')
	name = strings.TrimSpace(name)
	if name != "gomoku" && name != "connect6" {
		panic(fmt.Sprintf("unknown game: %q", name))
	}

	uiOut(ui, "game-name %s\n", name)

	var openingMoves []game.Move
	if name == "gomoku" {
		openingMoves = gomokuOpeningMoves()
	} else {
		openingMoves = connect6OpeningMoves()
	}

	for _, move := range openingMoves {
		fmt.Fprintf(black.out, "move %s\n", move)
		fmt.Fprintf(white.out, "move %s\n", move)
		uiOut(ui, "move %s\n", move)
	}

	if len(openingMoves)%2 == 1 {
		playMove(white, black, ui, millis)
	}

	dec := ""
	for {
		dec = playMove(black, white, ui, millis)
		if dec != common.NoDecision.String() {
			fmt.Fprintln(white.out, "stop")
			break
		}
		dec = playMove(white, black, ui, millis)
		if dec != common.NoDecision.String() {
			fmt.Fprintln(black.out, "stop")
			break
		}
	}
	<-time.After(3 * time.Second)
	fmt.Fprintln(ui.out, "clear")
}

func gomokuOpeningMoves() []game.Move {
	moves := []game.Move{{P1: game.Place{X: game.Size / 2, Y: game.Size / 2}, P2: game.Place{X: game.Size / 2, Y: game.Size / 2}}}
	random := randomPlaces()
	for range 4 {
		r := rand.Intn(len(random))
		place := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		moves = append(moves, game.Move{P1: place, P2: place})
	}
	return moves
}

func connect6OpeningMoves() []game.Move {
	places := []game.Move{{
		P1: game.Place{X: game.Size / 2, Y: game.Size / 2},
		P2: game.Place{X: game.Size / 2, Y: game.Size / 2}}}
	random := randomPlaces()
	for range 2 {
		r := rand.Intn(len(random))
		place1 := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		r = rand.Intn(len(random))
		place2 := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		places = append(places, game.Move{P1: place1, P2: place2})
	}
	return places
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

func wait(cmd *Cmd) {
	cmd.cmd.Wait()
	os.Exit(0)
}

func uiOut(ui *Cmd, format string, args ...any) {
	fmt.Fprintf(ui.out, format, args...)
}

func playMove(maker, taker, ui *Cmd, millis int64) string {
	fmt.Fprintf(maker.out, "respond %d\n", millis)
	response, _ := maker.in.ReadString('\n')
	uiOut(ui, "%s", response)
	fmt.Fprint(taker.out, response)
	return decision(maker)
}

func decision(cmd *Cmd) string {
	fmt.Fprintln(cmd.out, "decision")
	response, _ := cmd.in.ReadString('\n')
	terms := strings.Fields(response)
	return terms[1]
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
