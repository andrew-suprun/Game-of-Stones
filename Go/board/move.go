package board

type Move struct {
	value    int16
	terminal bool
}

func Make(value int16, terminal bool) Move {
	return Move{value: value, terminal: terminal}
}

func (m Move) Value() int16 {
	return m.value
}

func (m *Move) SetValue(value int16) {
	m.value = value
}

func (m Move) IsDecisive() bool {
	return m.terminal || m.value <= -WinValue || m.value >= WinValue
}

func (m Move) IsTerminal() bool {
	return m.terminal
}
