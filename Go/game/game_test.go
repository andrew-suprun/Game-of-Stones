package game

import (
	"fmt"
	"testing"

	. "game_of_stones/common"
)

func TestString(t *testing.T) {
	move := Move{P1: Place{1, 2}, P2: Place{3, 4}}
	moveValue := MoveValue[Move]{Move: move, Value: 5, Decision: BlackWin}
	result := fmt.Sprintf("%v", moveValue)
	fmt.Println(result)
	if result != "b17-d15 v:    5 BlackWin" {
		t.Fail()
	}
}

func TestMove(t *testing.T) {
	c6 := NewGame(Connect6, 10)
	m1, _ := c6.ParseMove("j10")
	c6.PlayMove(m1)
	m2, _ := c6.ParseMove("i9-i11")
	c6.PlayMove(m2)
	fmt.Printf("%#v\nopp V: %v\n", c6, c6.oppValue())
}

func TestTopMoves(t *testing.T) {
	c6 := NewGame(Connect6, 10)
	originalBoard := c6.values
	m1, _ := c6.ParseMove("j10")
	c6.PlayMove(m1)
	m2, _ := c6.ParseMove("i9-i11")
	fmt.Println(m2)
	c6.PlayMove(m2)
	fmt.Println(c6)

	moves := make([]MoveValue[Move], 0, 1)

	played := []Move{}

	for {
		c6.TopMoves(&moves)
		for _, move := range moves {
			c6.PlayMove(move.Move)
			// fmt.Printf("Move %d: %#v\n%v\n", i+1, move, c6)
			c6.UndoMove(move.Move)
		}

		c6.PlayMove(moves[0].Move)
		fmt.Printf("%#v\n%v\n", moves[0], c6)
		played = append(played, moves[0].Move)
		if moves[0].Decision != NoDecision {
			break
		}
	}
	for i := range len(played) {
		c6.UndoMove(played[len(played)-1-i])
	}

	c6.UndoMove(m2)
	c6.UndoMove(m1)

	if originalBoard != c6.values {
		t.Fail()
	}
}
