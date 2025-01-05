package connect6

import (
	"fmt"
	"game_of_stones/board"
)

type Move struct {
	board.Move
	P1, P2 board.Place
}

func MakeMove(x1, y1, x2, y2 int8, value int16, terminal bool) Move {
	return Move{P1: board.Place{X: x1, Y: y1}, P2: board.Place{X: x2, Y: y2}, Move: board.Make(value, terminal)}
}

func (m Move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.P1.X+'a', board.Size-m.P1.Y, m.P2.X+'a', board.Size-m.P2.Y)
}

func (m Move) GoString() string {
	state := ""
	if m.IsTerminal() {
		state = " Terminal"
	} else if m.IsDecisive() {
		state = " Decisive"
	}
	return fmt.Sprintf("%-7v v: %4d%s", m, m.Value(), state)
}
