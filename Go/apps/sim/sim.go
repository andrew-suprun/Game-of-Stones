package main

import (
	"bufio"
	"fmt"
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
	black := startEngine(os.Args[1])
	white := startEngine(os.Args[2])
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
	ui := startEngine("ui")

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
		if result := makeMove(black, white, ui); result != "" {
			fmt.Printf("black %q\n", result)
			break
		}
		if result := makeMove(white, black, ui); result != "" {
			fmt.Printf("white %q\n", result)
			break
		}
	}

	fmt.Println("stopping")
	<-time.After(4 * time.Second)
	fmt.Println("stopped")
}

func uiOut(ui *Cmd, format string, args ...any) {
	fmt.Fprintf(ui.out, format, args...)
}

func makeMove(maker, taker, ui *Cmd) string {
	fmt.Fprintln(maker.out, "respond 1000")
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

func startEngine(path string) *Cmd {
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
	go runLogger(bufio.NewReader(log))
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

func runLogger(log *bufio.Reader) {
	for {
		line, err := log.ReadString('\n')
		if err == io.EOF {
			return
		}
		if err != nil {
			panic(err)
		}
		fmt.Print(line)
	}
}

func firstWhiteGomokuMove() string {
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+8+'a', j+8))
			}
		}
	}

	return places[rand.Intn(8)]
}

func firstWhiteConnect6Move() string {
	places := []string{}
	for j := range 3 {
		for i := range 3 {
			if i != 1 || j != 1 {
				places = append(places, fmt.Sprintf("%c%d", i+'i', j+9))
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
