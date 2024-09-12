package board

import (
	"math/rand"
	"testing"
)

func TestScores(t *testing.T) {
	for i := range 100 {
		board := Board{}
		var rng = rand.New(rand.NewSource(int64(i)))
		var score int32 = 0
		for range 100 {
			x := byte(rng.Intn(Size))
			y := byte(rng.Intn(Size))
			if board[y][x] != None {
				continue
			}
			if rng.Intn(2) == 0 {
				score += board.RatePlace(x, y, Black)
				board[y][x] = Black
			} else {
				score += board.RatePlace(x, y, White)
				board[y][x] = White
			}
		}
		scores := board.CalcScores(Black)
		for y := range Size {
			for x := range Size {
				score := board.RatePlace(byte(x), byte(y), Black)
				if score != scores[y][x] {
					t.Fail()
				}
			}
		}
		scores = board.CalcScores(White)
		for y := range Size {
			for x := range Size {
				score := board.RatePlace(byte(x), byte(y), White)
				if score != scores[y][x] {
					t.Fail()
				}
			}
		}
	}
}

func BenchmarkCalcBoard(b *testing.B) {
	bd := Board{}
	for range b.N {
		scores := bd.CalcScores(Black)
		if int(scores[0][0]) != 6 {
			b.Log("scores", scores[0][0], "N", b.N)
			b.FailNow()
		}
	}
}
func BenchmarkRatePlace(b *testing.B) {
	bd := &Board{}
	for range b.N {
		bd.RatePlace(9, 9, Black)
	}
}
