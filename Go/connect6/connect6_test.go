package connect6

import (
	"fmt"
	"game_of_stones/board"
	"game_of_stones/tree"
	"testing"
)

func TestGoString(t *testing.T) {
	result := fmt.Sprintf("%[1]v: %#[1]v", Move{1, 2, 3, 4, tree.Draw})
	fmt.Println(result)
	if result != "b17-d15: b17-d15 Draw" {
		t.Fail()
	}
}

func TestMove(t *testing.T) {
	c6 := NewGame(10)
	m1, _ := c6.ParseMove("j10-j10")
	c6.PlayMove(m1)
	m2, _ := c6.ParseMove("i9-i11")
	c6.PlayMove(m2)
	fmt.Printf("%#v\n", &c6.board)
	c6.board.PlaceStone(board.Black, 7, 9)
	fmt.Printf("%#v\n", &c6.board)
	c6.board.PlaceStone(board.Black, 8, 9)
	fmt.Printf("%#v\nopp V: %v\n", &c6.board, c6.oppValue())
}

func TestTopMoves(t *testing.T) {
	c6 := NewGame(10)
	originalBoard := c6.board
	m1, _ := c6.ParseMove("j10-j10")
	c6.PlayMove(m1)
	m2, _ := c6.ParseMove("i9+i11")
	c6.PlayMove(m2)

	moves := make([]tree.MoveValue[Move], 0, 1)

	played := []Move{}

	for {
		c6.TopMoves(&moves)
		for _, move := range moves {
			c6.PlayMove(move.Move)
			// fmt.Printf("Move %d: %#v\n%v\n", i+1, move, &c6.board)
			c6.UndoMove(move.Move)
		}

		c6.PlayMove(moves[0].Move)
		fmt.Printf("%#v\n%v\n", moves[0].Move, &c6.board)
		played = append(played, moves[0].Move)
		if moves[0].Move.State() == tree.BlackWin || moves[0].Move.State() == tree.WhiteWin {
			break
		}
	}
	for i := range len(played) {
		c6.UndoMove(played[len(played)-1-i])
	}

	c6.UndoMove(m2)
	c6.UndoMove(m1)

	if originalBoard != c6.board {
		t.Fail()
	}
}
