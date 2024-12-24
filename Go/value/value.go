package value

import "fmt"

type Value int32

func (value Value) Less(other Value) bool {
	return value < other
}

type State byte

const (
	Nonterminal State = iota
	Draw
	Win
)

const (
	DrawValue Value = 1
	WinValue  Value = 50_000
)

func (value Value) State() State {
	if value < -WinValue || value > WinValue {
		return Win
	} else if value == DrawValue {
		return Draw
	}
	return Nonterminal
}

func (value Value) String() string {
	if value < -WinValue || value > WinValue {
		return "Win"
	} else if value == DrawValue {
		return "Draw"
	}
	return fmt.Sprintf("%d", value)
}

func (value Value) GoString() string {
	return fmt.Sprintf("value.Value(%d)", value)
}

func (state State) String() string {
	switch state {
	case Nonterminal:
		return "Nonterminal"
	case Draw:
		return "Draw"
	case Win:
		return "Win"
	}
	return ""
}

func (state State) GoString() string {
	switch state {
	case Nonterminal:
		return "value.Nonterminal"
	case Draw:
		return "value.Draw"
	case Win:
		return "value.Win"
	}
	return ""
}
