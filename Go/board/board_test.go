package board

import (
	"fmt"
	"math/rand"
	"testing"
)

func (b *Board) testBoardScores() *[Size][Size][2]Score {
	scores := &[Size][Size][2]Score{}
	for y := 0; y < Size; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.Stones[y][x]
		}
		for x := 0; x < Size-maxStones1; x++ {
			stones += b.Stones[y][x+maxStones1]
			blackScore, whiteScore := testPlaceScores(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y][x+i][0] += blackScore
				scores[y][x+i][1] += whiteScore
			}
			stones -= b.Stones[y][x]
		}
	}

	for x := 0; x < Size; x++ {
		stones := Stone(0)
		for y := 0; y < maxStones1; y++ {
			stones += b.Stones[y][x]
		}
		for y := 0; y < Size-maxStones1; y++ {
			stones += b.Stones[y+maxStones1][x]
			blackScore, whiteScore := testPlaceScores(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y+i][x][0] += blackScore
				scores[y+i][x][1] += whiteScore
			}
			stones -= b.Stones[y][x]
		}
	}

	for y := 0; y < Size-maxStones1; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.Stones[y+x][x]
		}
		for x := 0; x < Size-maxStones1-y; x++ {
			stones += b.Stones[x+y+maxStones1][x+maxStones1]
			blackScore, whiteScore := testPlaceScores(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[x+y+i][x+i][0] += blackScore
				scores[x+y+i][x+i][1] += whiteScore
			}
			stones -= b.Stones[x+y][x]
		}
	}

	for x := 1; x < Size-maxStones1; x++ {
		stones := Stone(0)
		for y := 0; y < maxStones1; y++ {
			stones += b.Stones[y][x+y]
		}
		for y := 0; y < Size-maxStones1-x; y++ {
			stones += b.Stones[y+maxStones1][x+y+maxStones1]
			blackScore, whiteScore := testPlaceScores(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y+i][x+y+i][0] += blackScore
				scores[y+i][x+y+i][1] += whiteScore
			}
			stones -= b.Stones[y][x+y]
		}
	}

	for y := 0; y < Size-maxStones1; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.Stones[x+y][Size-1-x]
		}
		for x := 0; x < Size-maxStones1-y; x++ {
			stones += b.Stones[x+y+maxStones1][Size-1-x-maxStones1]
			blackScore, whiteScore := testPlaceScores(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[x+y+i][Size-1-x-i][0] += blackScore
				scores[x+y+i][Size-1-x-i][1] += whiteScore
			}
			stones -= b.Stones[x+y][Size-1-x]
		}
	}

	for x := 1; x < Size-maxStones1; x++ {
		stones := Stone(0)
		for y := 0; y < maxStones1; y++ {
			stones += b.Stones[y][Size-1-x-y]
		}
		for y := 0; y < Size-maxStones1-x; y++ {
			stones += b.Stones[y+maxStones1][Size-1-maxStones1-x-y]
			blackScore, whiteScore := testPlaceScores(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y+i][Size-1-x-y-i][0] += blackScore
				scores[y+i][Size-1-x-y-i][1] += whiteScore
			}
			stones -= b.Stones[y][Size-1-x-y]
		}
	}

	return scores
}

// 1, 8, 56, 336, 1680
func testPlaceScores(stones Stone) (Score, Score) {
	switch stones {
	case 0x05:
		return 5040, -1680
	case 0x04:
		return 1344, -336
	case 0x03:
		return 280, -56
	case 0x02:
		return 48, -8
	case 0x01:
		return 7, -1
	case 0x00:
		return 1, -1
	case 0x10:
		return 1, -7
	case 0x20:
		return 8, -48
	case 0x30:
		return 56, -280
	case 0x40:
		return 336, -1344
	case 0x50:
		return 1680, -5040
	}
	return 0, 0
}

type testMove struct {
	x, y  int
	stone Stone
}

func TestPlaceStone(t *testing.T) {
	rnd := rand.New(rand.NewSource(3))
	moves := []testMove{}
	b := NewBoard()
	for range Size * Size {
		x := rnd.Intn(Size)
		y := rnd.Intn(Size)
		if b.Stones[y][x] != None {
			continue
		}
		stone := Black
		if rnd.Intn(2) == 0 {
			stone = White
		}
		moves = append(moves, testMove{x, y, stone})
		b.PlaceStone(stone, x, y)
		checkScores(t, b)
	}
	t.Logf("%#v\n", b)
	for i := len(moves) - 1; i >= 0; i-- {
		b.RemoveStone(moves[i].stone, moves[i].x, moves[i].y)
		checkScores(t, b)
	}
	t.Logf("%#v\n", b)
}

func checkScores(t *testing.T, b *Board) {
	scores := b.testBoardScores()
	for y := 0; y < Size; y++ {
		for x := 0; x < Size; x++ {
			if b.Stones[y][x] == None && b.Scores[y][x] != scores[y][x] {
				t.Logf("x=%d y=%d expected=%v got%v\n", x, y, scores[y][x], b.Scores[y][x])
				t.Fail()
			}
		}
	}
	if t.Failed() {
		for y := 0; y < Size; y++ {
			for x := 0; x < Size; x++ {
				switch b.Stones[y][x] {
				case Black:
					fmt.Print("   X")
				case White:
					fmt.Print("   O")
				case None:
					fmt.Printf("%4d", scores[y][x][0])
				}
			}
			fmt.Println()
		}
		fmt.Println()
		for y := 0; y < Size; y++ {
			for x := 0; x < Size; x++ {
				switch b.Stones[y][x] {
				case Black:
					fmt.Print("   X")
				case White:
					fmt.Print("   O")
				case None:
					fmt.Printf("%4d", scores[y][x][1])
				}
			}
			fmt.Println()
		}
		fmt.Println()
		t.Logf("%#v\n", b)
		t.FailNow()
	}
}
