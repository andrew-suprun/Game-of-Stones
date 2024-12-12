package score

import (
	"fmt"
	"game_of_stones/board"
)

type Score struct {
	move board.Score
	acc  board.Score
}

func MakeScore(move, acc board.Score) Score {
	return Score{move: move, acc: acc}
}

func (score Score) Value() board.Score {
	return score.acc
}

func (score Score) IsWinning() bool {
	return score.move <= -board.WinScore || score.move >= board.WinScore
}

func (score Score) IsDrawing() bool {
	return score.move == 0
}

func (score Score) GoString() string {
	if score.move < -board.WinScore || score.move > board.WinScore {
		return fmt.Sprintf("m:Win a:%#v", score.acc)
	}
	return fmt.Sprintf("m:%#v a:%#v", score.move, score.acc)
}
