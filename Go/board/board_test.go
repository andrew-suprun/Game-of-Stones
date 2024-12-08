package board

import (
	"fmt"
	"math/rand"
	"testing"
	"time"
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
		checkScores(t, &b)
	}
	t.Logf("%#v\n", &b)
	for i := len(moves) - 1; i >= 0; i-- {
		b.RemoveStone(moves[i].stone, moves[i].x, moves[i].y)
		checkScores(t, &b)
	}
	t.Logf("%#v\n", &b)
}

func BenchmarkPlaceStone(b *testing.B) {
	rnd := rand.New(rand.NewSource(3))
	moves := []testMove{}
	board := MakeBoard()

	b.ResetTimer()
	for range b.N {
		for range Size * Size {
			x := rnd.Intn(Size)
			y := rnd.Intn(Size)
			if board.stones[y][x] != None {
				continue
			}
			stone := Black
			if rnd.Intn(2) == 0 {
				stone = White
			}
			moves = append(moves, testMove{x, y, stone})
			board.PlaceStone(stone, x, y)
		}
		for i := len(moves) - 1; i >= 0; i-- {
			board.RemoveStone(moves[i].stone, moves[i].x, moves[i].y)
		}
	}
}

func TestTime(t *testing.T) {
	board := MakeBoard()
	n := 5_000_000

	start := time.Now()
	for range n {
		board.PlaceStone(Black, 9, 9)
		board.RemoveStone(Black, 9, 9)
	}
	fmt.Println("n", 2*n, "time", time.Since(start))
}

func (b *Board) testBoardScores() *[Size][Size][2]Score {
	scores := &[Size][Size][2]Score{}
	for y := 0; y < Size; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.stones[y][x]
		}
		for x := 0; x < Size-maxStones1; x++ {
			stones += b.stones[y][x+maxStones1]
			blackScore, whiteScore := testScoreStones(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y][x+i][0] += blackScore
				scores[y][x+i][1] += whiteScore
			}
			stones -= b.stones[y][x]
		}
	}

	for x := 0; x < Size; x++ {
		stones := Stone(0)
		for y := 0; y < maxStones1; y++ {
			stones += b.stones[y][x]
		}
		for y := 0; y < Size-maxStones1; y++ {
			stones += b.stones[y+maxStones1][x]
			blackScore, whiteScore := testScoreStones(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y+i][x][0] += blackScore
				scores[y+i][x][1] += whiteScore
			}
			stones -= b.stones[y][x]
		}
	}

	for y := 0; y < Size-maxStones1; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.stones[y+x][x]
		}
		for x := 0; x < Size-maxStones1-y; x++ {
			stones += b.stones[x+y+maxStones1][x+maxStones1]
			blackScore, whiteScore := testScoreStones(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[x+y+i][x+i][0] += blackScore
				scores[x+y+i][x+i][1] += whiteScore
			}
			stones -= b.stones[x+y][x]
		}
	}

	for x := 1; x < Size-maxStones1; x++ {
		stones := Stone(0)
		for y := 0; y < maxStones1; y++ {
			stones += b.stones[y][x+y]
		}
		for y := 0; y < Size-maxStones1-x; y++ {
			stones += b.stones[y+maxStones1][x+y+maxStones1]
			blackScore, whiteScore := testScoreStones(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y+i][x+y+i][0] += blackScore
				scores[y+i][x+y+i][1] += whiteScore
			}
			stones -= b.stones[y][x+y]
		}
	}

	for y := 0; y < Size-maxStones1; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.stones[x+y][Size-1-x]
		}
		for x := 0; x < Size-maxStones1-y; x++ {
			stones += b.stones[x+y+maxStones1][Size-1-x-maxStones1]
			blackScore, whiteScore := testScoreStones(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[x+y+i][Size-1-x-i][0] += blackScore
				scores[x+y+i][Size-1-x-i][1] += whiteScore
			}
			stones -= b.stones[x+y][Size-1-x]
		}
	}

	for x := 1; x < Size-maxStones1; x++ {
		stones := Stone(0)
		for y := 0; y < maxStones1; y++ {
			stones += b.stones[y][Size-1-x-y]
		}
		for y := 0; y < Size-maxStones1-x; y++ {
			stones += b.stones[y+maxStones1][Size-1-maxStones1-x-y]
			blackScore, whiteScore := testScoreStones(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y+i][Size-1-x-y-i][0] += blackScore
				scores[y+i][Size-1-x-y-i][1] += whiteScore
			}
			stones -= b.stones[y][Size-1-x-y]
		}
	}

	return scores
}

type testMove struct {
	x, y  int
	stone Stone
}

func checkScores(t *testing.T, b *Board) {
	scores := b.testBoardScores()
	for y := 0; y < Size; y++ {
		for x := 0; x < Size; x++ {
			if b.stones[y][x] == None && b.scores[y][x] != scores[y][x] {
				t.Logf("x=%d y=%d expected=%v got%v\n", x, y, scores[y][x], b.scores[y][x])
				t.Fail()
			}
		}
	}
	if t.Failed() {
		for y := 0; y < Size; y++ {
			for x := 0; x < Size; x++ {
				switch b.stones[y][x] {
				case Black:
					fmt.Print("    X")
				case White:
					fmt.Print("    O")
				case None:
					fmt.Printf("%5d", scores[y][x][0])
				}
			}
			fmt.Println()
		}
		fmt.Println()
		for y := 0; y < Size; y++ {
			for x := 0; x < Size; x++ {
				switch b.stones[y][x] {
				case Black:
					fmt.Print("    X")
				case White:
					fmt.Print("    O")
				case None:
					fmt.Printf("%5d", scores[y][x][1])
				}
			}
			fmt.Println()
		}
		fmt.Println()
		t.Logf("%#v\n", b)
		t.FailNow()
	}
}
