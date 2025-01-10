package game

import (
	"fmt"
	"game_of_stones/turn"
	"math/rand"
	"testing"
)

func TestPlaceStone(t *testing.T) {
	rnd := rand.New(rand.NewSource(3))
	moves := []testMove{}
	game := NewGame(Gomoku, 10)
	originalStones := game.stones
	originalValues := game.values
	for range 300 {
		y := int8(rnd.Intn(Size))
		x := int8(rnd.Intn(Size))
		if game.stones[y][x] != None {
			continue
		}
		stone := Black
		if rnd.Intn(2) == 0 {
			stone = White
		}
		moves = append(moves, testMove{Place{x, y}, stone})
		game.stone = stone
		game.placeStone(Place{x, y}, 1)
	}
	t.Logf("%#v\n", game)
	for i := len(moves) - 1; i >= 0; i-- {
		game.stone = moves[i].stone
		game.placeStone(moves[i].place, -1)
	}
	t.Logf("%#v\n", game)
	if originalStones != game.stones || originalValues != game.values {
		t.Fail()
	}
}

func TestTopPlaces(t *testing.T) {
	game := NewGame(Connect6, 1)
	p1, _ := parsePlace("j10")
	p2, _ := parsePlace("i9")
	p3, _ := parsePlace("i11")
	p4, _ := parsePlace("i10")
	game.placeStone(p1, 1)
	game.stone = White
	game.turn = turn.Second
	game.placeStone(p2, 1)
	game.placeStone(p3, 1)
	game.stone = Black
	game.topPlaces()
	if game.places[0] != p4 {
		fmt.Printf("%#v\n", game)
		t.Fail()
	}
}

func BenchmarkTime(b *testing.B) {
	board := NewGame(Connect6, 10)

	b.ResetTimer()
	for range b.N {
		board.placeStone(Place{9, 9}, 1)
		board.placeStone(Place{9, 9}, -1)
	}
}

type testMove struct {
	place Place
	stone Stone
}
