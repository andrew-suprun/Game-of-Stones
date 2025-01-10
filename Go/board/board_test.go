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
		y := int8(rnd.Intn(Size))
		x := int8(rnd.Intn(Size))
		if b.stones[y][x] != None {
			continue
		}
		stone := Black
		if rnd.Intn(2) == 0 {
			stone = White
		}
		moves = append(moves, testMove{Place{x, y}, stone})
		b.PlaceStone(stone, Place{x, y})
	}
	t.Logf("%#v\n", &b)
	for i := len(moves) - 1; i >= 0; i-- {
		b.RemoveStone(moves[i].stone, moves[i].place)
	}
	t.Logf("%#v\n", &b)
}

func TestTopPlaces(t *testing.T) {
	b := MakeBoard()
	p1, _ := ParsePlace("j10")
	p2, _ := ParsePlace("i9")
	p3, _ := ParsePlace("i11")
	p4, _ := ParsePlace("i10")
	b.PlaceStone(Black, p1)
	b.PlaceStone(White, p2)
	b.PlaceStone(White, p3)
	places := make([]Place, 0, 1)
	b.TopPlaces(Black, &places)
	if places[0] != p4 {
		t.Fail()
	}
}

func BenchmarkTime(b *testing.B) {
	board := MakeBoard()

	b.ResetTimer()
	for range b.N {
		board.PlaceStone(Black, Place{9, 9})
		board.RemoveStone(Black, Place{9, 9})
	}
}

type testMove struct {
	place Place
	stone Stone
}
