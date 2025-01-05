package board

type Move struct {
	value    float32
	terminal bool
}

func Make(value float32, terminal bool) Move {
	return Move{value: value, terminal: terminal}
}

func (m Move) Value() float32 {
	return m.value
}

func (m *Move) SetValue(value float32) {
	m.value = value
}

func (m Move) IsDecisive() bool {
	return m.terminal || m.value <= -WinValue || m.value >= WinValue
}

func (m Move) IsTerminal() bool {
	return m.terminal
}
