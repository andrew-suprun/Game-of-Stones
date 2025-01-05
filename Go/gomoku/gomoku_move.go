package gomoku

import (
	"fmt"
	"game_of_stones/board"
)

type Move struct {
	board.Move
	Place board.Place
}

func MakeMove(x, y int8, value int16, terminal bool) Move {
	return Move{Place: board.Place{X: x, Y: y}, Move: board.Make(value, terminal)}
}

func (m Move) String() string {
	return fmt.Sprintf("%c%d", m.Place.X+'a', board.Size-m.Place.Y)
}

func (m Move) GoString() string {
	state := ""
	if m.IsTerminal() {
		state = " Terminal"
	} else if m.IsDecisive() {
		state = " Decisive"
	}
	return fmt.Sprintf("%-3v v: %4d%s", m, m.Value(), state)
}
