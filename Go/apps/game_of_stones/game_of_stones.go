package main

import (
	"bufio"
	"flag"
	"fmt"
	"game_of_stones/common"
	"game_of_stones/game"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

var (
	engine = flag.String("engine", "gomoku", "path to engine")
	spm    = flag.Float64("spm", 1, "seconds per move")
)

type Cmd struct {
	name string
	cmd  *exec.Cmd
	in   *bufio.Reader
	out  io.Writer
}

type gameOfStones struct {
	name   string
	engine *Cmd
	ui     *Cmd
}

func main() {
	flag.Parse()
	logChan := make(chan string, 1)
	go logPrinter(logChan)

	engine := startEngine(*engine, logChan)
	gameName := engine.call("game-name")
	parts := strings.Fields(gameName)
	gameName = parts[1]
	ui := startEngine("ui", logChan)
	go ui.wait()

	ui.send("game-name %s", gameName)

	game := gameOfStones{
		name:   gameName,
		engine: engine,
		ui:     ui,
	}

	ui.send("move j10")
	engine.send("move j10")

	firstEngineMove := false

	millis := int(*spm * 1000)

	for {
		uiMove := ui.call("respond")
		if uiMove == "skip" {
			firstEngineMove = true
		} else if uiMove == "undo" {
			engine.send("undo")
			engine.send("undo")
			ui.send("undo")
			continue
		} else {
			engine.send(uiMove)
			dec := engine.call("decision")
			terms := strings.Fields(dec)
			if len(terms) > 1 && terms[1] != common.NoDecision.String() {
				break
			}
		}
		if firstEngineMove {
			game.playFirstWhiteStones()
			firstEngineMove = false
		} else {
			engineMove := engine.call("respond %d", millis)
			ui.send(engineMove)
			dec := engine.call("decision")
			terms := strings.Fields(dec)
			if len(terms) > 1 && terms[1] != common.NoDecision.String() {
				break
			}
		}
	}

	<-time.After(10 * time.Minute)
}

func startEngine(path string, logChan chan string) *Cmd {
	name := strings.Fields(path)[0]
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
	return &Cmd{name, cmd, bufio.NewReader(in), out}
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
		logChan <- name + ": log: " + line
	}
}

func logPrinter(logChan chan string) {
	for {
		line := <-logChan
		line = strings.TrimSpace(line)
		fmt.Fprintln(os.Stderr, line)
	}
}

func (game *gameOfStones) playFirstWhiteStones() {
	move := ""
	random := randomPlaces()
	if game.name == "connect6" {
		r := rand.Intn(len(random))
		place1 := random[r]
		random[r] = random[len(random)-1]
		random = random[:len(random)-1]
		r = rand.Intn(len(random))
		place2 := random[r]
		move = fmt.Sprintf("move %s-%s", place1, place2)
	} else {
		r := rand.Intn(len(random))
		place := random[r]
		move = fmt.Sprintf("move %s", place)
	}
	game.ui.send(move)
	game.engine.send(move)
}

func randomPlaces() []game.Place {
	random := []game.Place{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				random = append(random, game.Place{X: int8(game.Size/2 - 1 + i), Y: int8(game.Size/2 - 1 + j)})
			}
		}
	}
	return random
}

func (cmd *Cmd) call(format string, args ...any) string {
	cmd.send(format, args...)
	in, _ := cmd.in.ReadString('\n')
	in = strings.TrimSpace(in)
	fmt.Printf("%s: got %q\n", cmd.name, in)
	return in
}

func (cmd *Cmd) send(format string, args ...any) {
	text := fmt.Sprintf(format, args...)
	fmt.Fprintln(cmd.out, text+"\n")
	fmt.Printf("%s: sent %q\n", cmd.name, text)
}

func (cmd *Cmd) wait() {
	cmd.cmd.Wait()
	os.Exit(0)
}
