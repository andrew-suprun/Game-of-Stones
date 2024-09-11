package game

import (
	"fmt"
	"testing"
)

func TestScores(t *testing.T) {
	b := &board{}
	b[9][9] = black
	// b[9][8] = white
	// b[8][8] = white
	fmt.Println(b)
	scores := b.calcScores(black)
	fmt.Println(&scores)
}

func BenchmarkCalcBoard(b *testing.B) {
	bd := board{}
	scores := scores{}
	b.ResetTimer()
	for range b.N {
		scores = bd.calcScores(black)
		if int(scores[0][0]) != 1 {
			b.Log("scores", scores[0][0], "N", b.N)
			b.FailNow()
		}
		scores[0][0] = 0
	}
}
