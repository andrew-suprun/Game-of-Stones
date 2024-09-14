package board

import (
	"fmt"
	"math/rand"
	"testing"
)

func TestScores(t *testing.T) {
	for i := range 100 {
		fmt.Println("Run", i)
		board := Board{}
		var rng = rand.New(rand.NewSource(int64(i)))
		var score int16 = 0
		for range 100 {
			x := byte(rng.Intn(Size))
			y := byte(rng.Intn(Size))
			if board.stones[y][x] != None {
				continue
			}
			if rng.Intn(2) == 0 {
				score += board.RatePlace(x, y, Black)
				board.stones[y][x] = Black
			} else {
				score += board.RatePlace(x, y, White)
				board.stones[y][x] = White
			}
		}
		scores := board.CalcScores(Black)
		fmt.Println(&board)
		fmt.Println(&scores)
		for y := range Size {
			for x := range Size {
				score := board.RatePlace(byte(x), byte(y), Black)
				fmt.Println(x, y, score)
				if score != scores.Value(x, y) {
					t.FailNow()
				}
			}
		}
		scores = board.CalcScores(White)
		for y := range Size {
			for x := range Size {
				score := board.RatePlace(byte(x), byte(y), White)
				fmt.Println(x, y, score)
				if score != scores.Value(x, y) {
					t.FailNow()
				}
			}
		}
	}
}

func BenchmarkCalcBoard(b *testing.B) {
	bd := Board{}
	for range b.N {
		scores := bd.CalcScores(Black)
		if int(scores.Value(0, 0)) != 6 {
			b.Log("scores", scores.Value(0, 0), "N", b.N)
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

func BenchmarkStone(b *testing.B) {
	board := &Board{}
	count := 0
	for range b.N {
		stone := Black
		if rand.Intn(2) == 0 {
			stone = White
		}
		board.PlaceStone(byte(rand.Intn(19)), byte(rand.Intn(19)), stone)
		stone2 := board.Stone(rand.Intn(19), rand.Intn(19))
		if stone == stone2 {
			count++
		}
	}
	fmt.Println(count)
}
