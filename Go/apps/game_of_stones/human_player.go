package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	. "game_of_stones/common"
	"game_of_stones/game"
)

type humanPlayer struct {
	gameId              game.GameName
	stones              Turn
	turn                Turn
	oppIn               chan string
	oppOut              chan string
	uiOut               io.Writer
	played              map[string]rune
	selected            map[string]struct{}
	humanStone          rune
	humanStoneSelected  rune
	engineStone         rune
	engineStoneSelected rune
}

func runHumanPlayer(gameId game.GameName, stones Turn, oppIn, oppOut chan string) *humanPlayer {
	self := &humanPlayer{
		gameId:   gameId,
		stones:   stones,
		turn:     stones,
		oppIn:    oppIn,
		oppOut:   oppOut,
		played:   map[string]rune{},
		selected: map[string]struct{}{},
	}
	if stones == First {
		self.humanStone = 'b'
		self.humanStoneSelected = 'B'
		self.engineStone = 'w'
		self.engineStoneSelected = 'W'
	} else {
		self.humanStone = 'w'
		self.humanStoneSelected = 'W'
		self.engineStone = 'b'
		self.engineStoneSelected = 'B'
	}

	uiPath := filepath.Join(filepath.Dir(os.Args[0]), "ui")
	uiCmd := exec.Command(uiPath)
	var err error
	self.uiOut, err = uiCmd.StdinPipe()
	if err != nil {
		panic(err)
	}
	uiIn, err := uiCmd.StdoutPipe()
	if err != nil {
		panic(err)
	}
	err = uiCmd.Start()
	if err != nil {
		panic(err)
	}
	defer uiCmd.Wait()

	go self.uiMoves(uiIn)
	go self.opponentMoves()

	if self.turn == First {
		fmt.Fprintf(self.uiOut, "set j10 b\n")
		self.played["j10"] = 'b'
		oppOut <- "j10"
		self.turn = Second
	}

	return self
}

func (player *humanPlayer) opponentMoves() {
	for {
		move := <-player.oppIn
		parts := strings.Split(move, ";")
		move = parts[0]

		if player.gameId == connect6Id {
			places := strings.Split(move, "-")
			for _, place := range places {
				player.played[place] = player.engineStoneSelected
				fmt.Fprintf(player.uiOut, "set %s %c\n", place, player.engineStoneSelected)
			}
		} else {
			player.played[move] = player.engineStoneSelected
			fmt.Fprintf(player.uiOut, "set %s %c\n", move, player.engineStoneSelected)
		}
		if len(parts) == 1 || parts[1] != "terminal" {
			player.turn = player.stones
		}
	}
}

func (player *humanPlayer) uiMoves(uiIn io.Reader) {
	reader := bufio.NewReader(uiIn)
	for {
		text, err := reader.ReadString('\n')
		text = strings.TrimSpace(text)
		if err == io.EOF {
			player.oppOut <- "stop"
			return
		}
		if err != nil {
			panic(err)
		}
		if player.turn != player.stones {
			continue
		}

		if text == "stop" {
			player.oppOut <- "stop"
			return
		}
		if strings.HasPrefix(text, "error: ") ||
			strings.HasPrefix(text, "info: ") {

			player.oppOut <- text
		} else if strings.HasPrefix(text, "click: ") {
			place := text[7:]

			if _, selected := player.selected[place]; selected {
				fmt.Fprintf(player.uiOut, "set %s %c\n", place, 'e')
				delete(player.played, place)
				delete(player.selected, place)
				continue
			}

			if _, played := player.played[place]; played {
				continue
			}

			if player.gameId == game.Gomoku && len(player.selected) == 1 {
				continue
			}

			if player.gameId == game.Connect6 && len(player.selected) == 2 {
				continue
			}

			player.played[place] = player.humanStoneSelected
			fmt.Fprintf(player.uiOut, "set %s %c\n", place, player.humanStoneSelected)
			player.selected[place] = struct{}{}
		} else if text == "key: Enter" {
			if player.gameId == gomokuId && len(player.selected) != 1 {
				continue
			}
			if player.gameId == connect6Id && len(player.selected) != 2 {
				continue
			}
			for move, stone := range player.played {
				switch stone {
				case 'B':
					fmt.Fprintf(player.uiOut, "set %s b\n", move)
				case 'W':
					fmt.Fprintf(player.uiOut, "set %s w\n", move)
				}
			}
			if gameId == connect6Id {
				var places []string
				for place := range player.selected {
					places = append(places, place)
				}
				move := places[0] + "-" + places[1]
				player.oppOut <- move
			} else {
				for move := range player.selected {
					player.oppOut <- move
				}
			}
			clear(player.selected)
			if player.stones == First {
				player.turn = Second
			} else {
				player.turn = First
			}
		}
	}
}
