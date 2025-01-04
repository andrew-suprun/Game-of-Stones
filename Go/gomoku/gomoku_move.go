package gomoku

import (
	"fmt"
	"game_of_stones/board"
)

type Move struct {
	X, Y     int8
	value    float32
	draw     bool
	terminal bool
}

func (m Move) Value() float32 {
	return m.value
}

func (m Move) IsDecisive() bool {
	return m.draw || m.value <= -board.WinValue || m.value >= board.WinValue
}

func (m Move) IsTerminal() bool {
	return m.terminal
}

func (m Move) IsDraw() bool {
	return m.draw
}

func (m Move) String() string {
	return fmt.Sprintf("%c%d", m.X+'a', board.Size-m.Y)
}

func (m Move) GoString() string {
	state := ""
	if m.IsTerminal() {
		state = " Terminal"
	} else if m.IsDecisive() {
		state = " Decisive"
	}
	return fmt.Sprintf("%-7s v: %.0f%s", m.String(), m.value, state)
}
