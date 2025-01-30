package common

import "fmt"

type Turn int

const (
	First Turn = iota
	Second
)

func (turn Turn) String() string {
	switch turn {
	case First:
		return "First"
	case Second:
		return "Second"
	}
	panic("Turn.String()")
}

type Equatable[T any] interface {
	Equal(t T) bool
}

type MoveValue[Move Equatable[Move]] struct {
	Move     Move
	Value    int16
	Decision Decision
}

func (m MoveValue[Move]) String() string {
	return fmt.Sprintf("%-7v v: %4d %s", m.Move, m.Value, m.Decision)
}

type Decision int8

const (
	NoDecision Decision = iota
	Draw
	FirstWin
	SecondWin
)

func (d Decision) String() string {
	switch d {
	case NoDecision:
		return "no-decision"
	case Draw:
		return "draw"
	case FirstWin:
		return "first-win"
	case SecondWin:
		return "second-win"
	}
	return "invalid-decision"
}
