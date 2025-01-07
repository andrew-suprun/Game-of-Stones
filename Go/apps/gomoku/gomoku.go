package main

import (
	"fmt"
	"game_of_stones/board"
	"game_of_stones/gomoku"
	"game_of_stones/tree"
	"game_of_stones/turn"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const usage = "Select color of your stones: gomoku [black|white]"

func main() {
	var humanPlayer turn.Turn
	if len(os.Args) == 2 {
		switch strings.ToLower(os.Args[1]) {
		case "black":
			humanPlayer = turn.First
		case "white":
			humanPlayer = turn.Second
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
	_ = reader
	if err != nil {
		panic(err)
	}
	err = uiCmd.Start()
	if err != nil {
		panic(err)
	}
	defer uiCmd.Wait()

	for {
		game := gomoku.NewGame(22)
		searchTree := tree.NewTree(game, 22, 20)
		_ = searchTree
		if humanPlayer == turn.First {
			fmt.Fprintf(writer, "set j10 b\n")
			move := firstWhiteMove()
			fmt.Fprintf(writer, "set %s W\n", move)
		}
		break
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
