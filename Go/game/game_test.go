package game

import (
	"fmt"
	"testing"

	. "game_of_stones/common"
)

func TestString(t *testing.T) {
	move := Move{P1: Place{1, 2}, P2: Place{3, 4}}
	moveValue := MoveValue[Move]{Move: move, Value: 5, Decision: FirstWin}
	result := fmt.Sprintf("%v", moveValue)
	fmt.Println(result)
	if result != "b3-d5   v:    5 first-win" {
		t.Fail()
	}
}

func TestMove(t *testing.T) {
	c6 := NewGame()
	m1, _ := ParseMove("j10")
	c6.PlayMove(m1)
	m2, _ := ParseMove("i9-i11")
	c6.PlayMove(m2)
}

func TestTopMoves(t *testing.T) {
	c6 := NewGame()
	originalBoard := c6.values
	m1, _ := ParseMove("j10")
	c6.PlayMove(m1)
	m2, _ := ParseMove("i9-i11")
	fmt.Println(m2)
	c6.PlayMove(m2)
	fmt.Println(c6)

	moves := make([]MoveValue[Move], 0, 1)

	played := []Move{}

	for {
		c6.TopMoves(&moves)
		c6.PlayMove(moves[0].Move)
		fmt.Printf("played %v\n%v\n", moves[0], c6)
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
	fmt.Printf("%#v\n", c6)

	if originalBoard != c6.values {
		t.Error("Fail")
	}
}
