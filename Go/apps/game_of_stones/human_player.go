package main

import (
	"bufio"
	"fmt"
	"game_of_stones/turn"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type humanPlayer struct {
	gameId              int
	stones              turn.Turn
	turn                turn.Turn
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

func newHumanPlayer(gameId int, stones turn.Turn, oppIn, oppOut chan string) *humanPlayer {
	self := &humanPlayer{
		gameId:   gameId,
		stones:   stones,
		turn:     stones,
		oppIn:    oppIn,
		oppOut:   oppOut,
		played:   map[string]rune{},
		selected: map[string]struct{}{},
	}
	if stones == turn.First {
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

	go self.humanMoves(uiIn)
	go self.opponentMoves()

	if self.turn == turn.First {
		fmt.Fprintf(self.uiOut, "set j10 b\n")
		self.played["j10"] = 'b'
		if self.gameId == connect6Id {
			oppOut <- "j10-j10"
		} else {
			oppOut <- "j10"
		}
		self.turn = turn.Second
	}

	return self
}

func (self *humanPlayer) opponentMoves() {
	for {
		move := <-self.oppIn
		if self.turn == self.stones {
			continue
		}
		if self.turn == turn.First {
			self.turn = turn.Second
		} else {
			self.turn = turn.First
		}
		if self.gameId == connect6Id {
			places := strings.Split(move, "-")
			for _, place := range places {
				self.played[place] = self.engineStoneSelected
				fmt.Fprintf(self.uiOut, "set %s %c\n", move, self.engineStoneSelected)
			}
		} else {
			self.played[move] = self.engineStoneSelected
			fmt.Fprintf(self.uiOut, "set %s %c\n", move, self.engineStoneSelected)
		}
	}
}

func (self *humanPlayer) humanMoves(uiIn io.Reader) {
	fmt.Println("start reader")
	reader := bufio.NewReader(uiIn)
	for {
		text, err := reader.ReadString('\n')
		fmt.Println("read", text)
		if err == io.EOF {
			self.oppOut <- "stop"
			return
		}
		if err != nil {
			panic(err)
		}
		if self.turn != self.stones {
			continue
		}
		if self.turn == turn.First {
			self.turn = turn.Second
		} else {
			self.turn = turn.First
		}

		fmt.Printf("text %q\n", text)
		if text == "stop" {
			self.oppOut <- "stop"
			return
		}
		if strings.HasPrefix(text, "error: ") ||
			strings.HasPrefix(text, "info: ") {

			self.oppOut <- text
		} else if strings.HasPrefix(text, "click: ") {
			move := text[7:]
			if _, ok := self.played[move]; ok {
				self.played[move] = 'e'
				fmt.Fprintf(self.uiOut, "set %s %c\n", move, 'e')
				delete(self.selected, move)
			} else {
				self.played[move] = self.humanStoneSelected
				fmt.Fprintf(self.uiOut, "set %s %c\n", move, self.humanStoneSelected)
				self.selected[move] = struct{}{}
			}
		} else if text == "key: Enter" {
			if self.gameId == gomokuId && len(self.selected) != 1 {
				continue
			}
			if self.gameId == connect6Id && len(self.selected) != 2 {
				continue
			}
			for move, stone := range self.played {
				switch stone {
				case 'B':
					fmt.Fprintf(self.uiOut, "set %s b\n", move)
				case 'W':
					fmt.Fprintf(self.uiOut, "set %s w\n", move)
				}
			}
			if gameId == connect6Id {
				var places []string
				for place := range self.selected {
					places = append(places, place)
					fmt.Fprintf(self.uiOut, "set %s %c\n", place, self.stones)
				}
				move := places[0] + "-" + places[1]
				self.oppOut <- move
			} else {
				for move := range self.selected {
					fmt.Fprintf(self.uiOut, "set %s %c\n", move, self.stones)
					self.oppOut <- move
				}
			}
		}
	}
}
