package connect6

import (
	"fmt"
	"game_of_stones/board"
	"game_of_stones/value"
	"testing"
)

func TestGoString(t *testing.T) {
	result := fmt.Sprintf("%[1]v: %#[1]v", makeMove(1, 2, 3, 4, 1, 0))
	fmt.Println(result)
	if result != "b17-d15: b17-d15 Draw" {
		t.Fail()
	}
}

func TestMove(t *testing.T) {
	c6 := NewGame(10)
	c6.PlayMove(c6.MakeMove(9, 9, 9, 9))
	c6.PlayMove(c6.MakeMove(8, 8, 8, 10))
	fmt.Printf("%#v\n", &c6.board)
	c6.board.PlaceStone(board.Black, 7, 9)
	fmt.Printf("%#v\n", &c6.board)
	c6.board.PlaceStone(board.Black, 8, 9)
	fmt.Printf("%#v\nopp V: %v\n", &c6.board, c6.oppValue())
}

func TestTopMoves(t *testing.T) {
	c6 := NewGame(10)
	originalBoard := c6.board
	c6.PlayMove(c6.MakeMove(9, 9, 9, 9))
	c6.PlayMove(c6.MakeMove(8, 8, 8, 10))

	moves := make([]Move, 0, 1)

	played := []Move{}

	for {
		c6.TopMoves(&moves)
		for _, move := range moves {
			c6.PlayMove(move)
			// fmt.Printf("Move %d: %#v\n%v\n", i+1, move, &c6.board)
			c6.UndoMove(move)
		}

		c6.PlayMove(moves[0])
		fmt.Printf("%#v\n%v\n", moves[0], &c6.board)
		played = append(played, moves[0])
		if moves[0].value.State() == value.Win {
			break
		}
	}
	for i := range len(played) {
		c6.UndoMove(played[len(played)-1-i])
	}

	c6.UndoMove(c6.MakeMove(8, 8, 8, 10))
	c6.UndoMove(c6.MakeMove(9, 9, 9, 9))

	if originalBoard != c6.board {
		t.Fail()
	}
}
