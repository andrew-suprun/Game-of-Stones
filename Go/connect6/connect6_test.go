package connect6

import (
	"fmt"
	"game_of_stones/board"
	"math"
	"testing"
)

func TestGoString(t *testing.T) {
	result := fmt.Sprintf("%[1]v: %#[1]v", makeMove(1, 2, 3, 4, 5))
	if result != "b17-d15: makeMove(1, 2, 3, 4, 5)" {
		t.Fail()
	}
}

func TestPossiblePlaces(t *testing.T) {
	c6 := NewGame(8)
	move, _ := c6.MakeMove("j10-j10")
	c6.PlayMove(move)
	move, _ = c6.MakeMove("i9-i10")
	c6.PlayMove(move)
	scores := c6.board.CalcScores(board.Black)
	places := c6.possiblePlaces(&scores)

	var maxPlace place
	for _, place := range places {
		if maxPlace.score < place.score {
			maxPlace = place
		}
	}

	if maxPlace.x != 8 || maxPlace.y != 10 {
		t.Fail()
	}
}

func TestMakeMove(t *testing.T) {
	c6 := NewGame(8)
	m, err := c6.MakeMove("i10-i11")
	if m.GoString() != "makeMove(8, 8, 8, 9, 126)" || err != nil {
		t.FailNow()
	}
}

func TestPossibleMoves(t *testing.T) {
	c6 := NewGame(8)
	move, _ := c6.MakeMove("j10-j10")
	c6.PlayMove(move)
	move, _ = c6.MakeMove("i9-i10")
	c6.PlayMove(move)
	moves := c6.PossibleMoves(math.MaxInt16)

	fmt.Println(c6.board.String())
	fmt.Println(moves)
	for i, move := range moves {
		fmt.Println(i+1, move.x1, move.y1, move.x2, move.y2, move.score)
	}
}
