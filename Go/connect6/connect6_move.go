package connect6

import (
	"fmt"
	"game_of_stones/board"
)

type Move struct {
	X1, Y1, X2, Y2 int8
	value          float32
	decisive       bool
	terminal       bool
}

func (m Move) Value() float32 {
	return m.value
}

func (m Move) IsDecisive() bool {
	return m.decisive || m.value <= -board.WinValue || m.value >= board.WinValue
}

func (m Move) IsTerminal() bool {
	return m.terminal
}

func (m Move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.X1+'a', board.Size-m.Y1, m.X2+'a', board.Size-m.Y2)
}

func (m Move) GoString() string {
	state := ""
	if m.terminal {
		state = " Terminal"
	} else if m.decisive {
		state = " Decisive"
	}
	return fmt.Sprintf("%-7s v: %.0f%s", m.String(), m.value, state)
}
