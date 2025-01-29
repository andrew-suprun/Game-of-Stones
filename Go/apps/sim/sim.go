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
	cmd1 := startEngine(os.Args[1])
	cmd2 := startEngine(os.Args[2])
	fmt.Fprintf(cmd1.out, "game-name\n")
	fmt.Fprintf(cmd2.out, "game-name\n")
	name1, _ := cmd1.in.ReadString('\n')
	name1 = strings.TrimSpace(name1)
	name2, _ := cmd2.in.ReadString('\n')
	name2 = strings.TrimSpace(name2)
	if name1 != name2 {
		panic(fmt.Sprintf("engings are playing different games: %q and %q", name1, name2))
	}
	if name1 != "gomoku" && name1 != "connect6" {
		panic(fmt.Sprintf("unknown game: %q", name1))
	}
	ui := startEngine("ui")

	results := make(map[string]int)
	for range 10 {
		results[play(name1, cmd1, cmd2, ui)] += 1
		results[play(name2, cmd2, cmd1, ui)] += 1
		if _, ok := results["stop"]; ok {
			break
		}
	}

	fmt.Println(results)
}

func play(name string, black, white, ui *Cmd) string {
	fmt.Fprintf(black.out, "move j10\n")
	fmt.Fprintf(white.out, "move j10\n")
	uiOut(ui, "move j10")
	whiteMove := ""
	if name == "gomoku" {
		whiteMove = fmt.Sprintf("move %s\n", firstWhiteGomokuMove())
	} else {
		whiteMove = fmt.Sprintf("move %s\n", firstWhiteConnect6Move())
	}
	fmt.Fprint(black.out, whiteMove)
	fmt.Fprint(white.out, whiteMove)
	uiOut(ui, whiteMove)
	for {
		if result := makeMove(black, white, ui); result != "" {
			fmt.Printf("black %q\n", result)
			return result
		}
		if result := makeMove(white, black, ui); result != "" {
			fmt.Printf("white %q\n", result)
			return result
		}
	}

}

func uiOut(ui *Cmd, msg string) {
	fmt.Fprintln(ui.out, msg)
}

func makeMove(maker, taker, ui *Cmd) string {
	fmt.Fprintln(maker.out, "respond 1000")
	response, _ := maker.in.ReadString('\n')
	uiOut(ui, response)
	response = strings.TrimSpace(response)
	parts := strings.Split(response, " ")

	if parts[0] == "stop" {
		return "stop"
	}

	fmt.Fprintf(taker.out, "move %s\n", parts[1])
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
