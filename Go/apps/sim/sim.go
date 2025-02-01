package main

import (
	"bufio"
	"fmt"
	"game_of_stones/common"
	"io"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
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
		panic("Expected 2 arguments.")
	}
	logChan := make(chan string, 1)
	go logPrinter(logChan)

	ui := startEngine("ui", logChan, "Ui")
	go waitForUi(ui)

	black := startEngine(os.Args[1], logChan, "X")
	white := startEngine(os.Args[2], logChan, "O")
	fmt.Fprintf(black.out, "game-name\n")
	fmt.Fprintf(white.out, "game-name\n")
	name, _ := black.in.ReadString('\n')
	name = strings.TrimSpace(name)
	name2, _ := white.in.ReadString('\n')
	name2 = strings.TrimSpace(name2)
	if name != name2 {
		panic(fmt.Sprintf("engings are playing different games: %q and %q", name, name2))
	}
	if name != "gomoku" && name != "connect6" {
		panic(fmt.Sprintf("unknown game: %q", name))
	}

	uiOut(ui, "game-name %s\n", name)

	fmt.Fprintf(black.out, "move j10\n")
	fmt.Fprintf(white.out, "move j10\n")
	uiOut(ui, "move j10\n")
	whiteMove := ""
	if name == "gomoku" {
		whiteMove = fmt.Sprintf("move %s\n", firstWhiteGomokuMove())
	} else {
		whiteMove = fmt.Sprintf("move %s\n", firstWhiteConnect6Move())
	}
	fmt.Fprint(black.out, whiteMove)
	fmt.Fprint(white.out, whiteMove)
	uiOut(ui, "%s", whiteMove)
	for {
		makeMove(black, white, ui)
		if isTerminal(black) {
			break
		}
		makeMove(white, black, ui)
		if isTerminal(white) {
			break
		}
	}

	fmt.Println("stopping")
	<-time.After(10 * time.Minute)
	fmt.Println("stopped")
}

func waitForUi(cmd *Cmd) {
	cmd.cmd.Wait()
	os.Exit(0)
}

func uiOut(ui *Cmd, format string, args ...any) {
	fmt.Fprintf(ui.out, format, args...)
}

func makeMove(maker, taker, ui *Cmd) string {
	fmt.Fprintln(maker.out, "respond 250")
	response, _ := maker.in.ReadString('\n')
	uiOut(ui, "%s", response)
	fmt.Fprint(taker.out, response)
	response = strings.TrimSpace(response)
	if response == "stop" {
		return "stop"
	}
	terms := strings.Fields(response)
	if len(terms) > 2 {
		return terms[2]
	}
	return ""
}

func isTerminal(cmd *Cmd) bool {
	fmt.Fprintln(cmd.out, "decision")
	response, _ := cmd.in.ReadString('\n')
	terms := strings.Fields(response)
	return len(terms) == 2 && terms[1] != common.NoDecision.String()
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

func firstWhiteGomokuMove() string {
	places := []string{}
	for j := range 5 {
		for i := range 5 {
			if i != 2 || j != 2 {
				places = append(places, fmt.Sprintf("%c%d", i+'h', j+8))
			}
		}
	}
	return places[rand.Intn(len(places))]
}

func firstWhiteConnect6Move() string {
	places := []string{}
	for j := range 5 {
		for i := range 5 {
			if i != 2 || j != 2 {
				places = append(places, fmt.Sprintf("%c%d", i+'h', j+8))
			}
		}
	}

	idx1 := rand.Intn(len(places))
	idx2 := idx1
	for idx1 == idx2 {
		idx2 = rand.Intn(len(places))
	}
	return places[idx1] + "-" + places[idx2]
}
