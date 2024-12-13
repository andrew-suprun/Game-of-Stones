package score

import "fmt"

type Score int32

type State byte

const (
	Nonterminal State = iota
	Draw
	Win
)

const DrawScore = 1
const winScore = 50_000

func (score Score) State() State {
	if score < -winScore || score > winScore {
		return Win
	} else if score == DrawScore {
		return Draw
	}
	return Nonterminal
}

func (score Score) String() string {
	if score < -winScore || score > winScore {
		return "Win"
	} else if score == DrawScore {
		return "Draw"
	}
	return fmt.Sprintf("%d", score)
}

func (score Score) GoString() string {
	return fmt.Sprintf("score.Score(%d)", score)
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
		return "score.Nonterminal"
	case Draw:
		return "score.Draw"
	case Win:
		return "score.Win"
	}
	return ""
}
