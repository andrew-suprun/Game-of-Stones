package game

import (
	"fmt"
	"math/rand"
	"testing"

	. "game_of_stones/common"
)

func TestBoardValues(t *testing.T) {
	game := NewGame()

	rnd := rand.New(rand.NewSource(1))
	for range 100 {
		stone := Black
		if rnd.Intn(2) == 0 {
			stone = White
		}
		x, y := rnd.Intn(Size), rnd.Intn(Size)
		game.stones[y][x] = stone
	}

	values := game.BoardValues()
	for y := range Size {
		for x := range Size {
			if game.stones[y][x] != None {
				continue
			}
			v0 := game.BoardValue()
			game.stones[y][x] = Black
			v1 := game.BoardValue()
			if values[y][x][0] != v1-v0 {
				fmt.Printf("Failure:1: [%d:%d] expected %d got %d\n", x, y, v1-v0, values[y][x][0])
				t.FailNow()
			}
			game.stones[y][x] = White
			v2 := game.BoardValue()
			if values[y][x][1] != v2-v0 {
				fmt.Printf("Failure:2: [%d:%d] expected %d got %d\n", x, y, v2-v0, values[y][x][1])
				t.FailNow()
			}
			game.stones[y][x] = None
		}
	}
}

func TestPlaceStone(t *testing.T) {
	rnd := rand.New(rand.NewSource(3))
	moves := []testMove{}
	game := NewGame()
	originalStones := game.stones
	originalValues := game.values
	for range 300 {
		y := int8(rnd.Intn(Size))
		x := int8(rnd.Intn(Size))
		if game.stones[y][x] != None {
			continue
		}
		stone := Black
		turn := First
		if rnd.Intn(2) == 0 {
			stone = White
			turn = Second
		}
		moves = append(moves, testMove{Place{x, y}, stone})
		game.stone = stone
		game.turn = turn
		game.placeStone(Place{x, y}, 1)
	}
	// t.Logf("%#v\n", game)
	for i := len(moves) - 1; i >= 0; i-- {
		game.stone = moves[i].stone
		if game.stone == Black {
			game.turn = First
		} else {
			game.turn = Second
		}
		game.placeStone(moves[i].place, -1)
	}
	if originalStones != game.stones || originalValues != game.values {
		t.Logf("%#v\n", game)
		t.Fail()
	}
}

func BenchmarkPlayMove(b *testing.B) {
	board := NewGame()

	b.ResetTimer()
	for range b.N {
		board.PlayMove(Move{Place{9, 9}, Place{10, 10}})
		board.UndoMove(Move{Place{9, 9}, Place{10, 10}})
	}
}

func BenchmarkPlaceStone(b *testing.B) {
	board := NewGame()

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
