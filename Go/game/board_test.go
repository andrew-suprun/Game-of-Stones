package game

import (
	"math/rand"
	"testing"
)

func TestScores(t *testing.T) {
	for i := range 100 {
		board := board{}
		var rng = rand.New(rand.NewSource(int64(i)))
		var score int32 = 0
		for range 100 {
			x := byte(rng.Intn(boardSize))
			y := byte(rng.Intn(boardSize))
			if board[y][x] != none {
				continue
			}
			if rng.Intn(2) == 0 {
				score += board.ratePlace(x, y, black)
				board[y][x] = black
			} else {
				score += board.ratePlace(x, y, white)
				board[y][x] = white
			}
		}
		scores := board.calcScores(black)
		for y := range boardSize {
			for x := range boardSize {
				score := board.ratePlace(byte(x), byte(y), black)
				if score != scores[y][x] {
					t.Fail()
				}
			}
		}
		scores = board.calcScores(white)
		for y := range boardSize {
			for x := range boardSize {
				score := board.ratePlace(byte(x), byte(y), white)
				if score != scores[y][x] {
					t.Fail()
				}
			}
		}
	}
}

func BenchmarkCalcBoard(b *testing.B) {
	bd := board{}
	for range b.N {
		scores := bd.calcScores(black)
		if int(scores[0][0]) != 6 {
			b.Log("scores", scores[0][0], "N", b.N)
			b.FailNow()
		}
	}
}
func BenchmarkMakeMove(b *testing.B) {
	c := Connect6{turn: black}
	for range b.N {
		c.MakeMove(move{1, 2, 3, 4, 5})
		c.UnmakeMove(move{1, 2, 3, 4, 5})
	}
}

func BenchmarkRatePlace(b *testing.B) {
	bd := &board{}
	for range b.N {
		bd.ratePlace(9, 9, black)
	}
}
