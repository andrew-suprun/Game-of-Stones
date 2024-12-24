package board

import (
	"math/rand"
	"testing"
)

func TestPlaceStone(t *testing.T) {
	rnd := rand.New(rand.NewSource(3))
	moves := []testMove{}
	b := MakeBoard()
	for range 300 {
		x := rnd.Intn(Size)
		y := rnd.Intn(Size)
		if b.stones[y][x] != None {
			continue
		}
		stone := Black
		if rnd.Intn(2) == 0 {
			stone = White
		}
		moves = append(moves, testMove{x, y, stone})
		b.PlaceStone(stone, x, y)
	}
	t.Logf("%#v\n", &b)
	for i := len(moves) - 1; i >= 0; i-- {
		b.RemoveStone(moves[i].stone, moves[i].x, moves[i].y)
	}
	t.Logf("%#v\n", &b)
}

func TestTopPlaces(t *testing.T) {
	b := MakeBoard()
	b.PlaceStone(Black, 9, 9)
	b.PlaceStone(White, 8, 8)
	b.PlaceStone(White, 8, 10)
	places := make([]Place, 0, 3)
	b.TopPlaces(Black, &places)
	if places[0] != (Place{10, 9}) {
		t.Fail()
	}
}

func BenchmarkTime(b *testing.B) {
	board := MakeBoard()

	b.ResetTimer()
	for range b.N {
		board.PlaceStone(Black, 9, 9)
		board.RemoveStone(Black, 9, 9)
	}
}

type testMove struct {
	x, y  int
	stone Stone
}
