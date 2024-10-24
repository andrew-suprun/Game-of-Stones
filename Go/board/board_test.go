package board

import (
	"fmt"
	"testing"
)

func (b *Board) testBoardScores() *[Size][Size][2]Score {
	scores := &[Size][Size][2]Score{}
	for y := 0; y < Size; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.stones[y][x]
		}
		for x := 0; x < Size-maxStones1; x++ {
			stones += b.stones[y][x+maxStones1]
			blackScore, whiteScore := testPlaceScores(stones)
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
			blackScore, whiteScore := testPlaceScores(stones)
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
			blackScore, whiteScore := testPlaceScores(stones)
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
			blackScore, whiteScore := testPlaceScores(stones)
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
			blackScore, whiteScore := testPlaceScores(stones)
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
			blackScore, whiteScore := testPlaceScores(stones)
			// fmt.Printf("x=%d y=%d stones=0x%02x black=%d white=%d\n", x, y, stones, blackScore, whiteScore)
			for i := 0; i < maxStones; i++ {
				scores[y+i][Size-1-x-y-i][0] += blackScore
				scores[y+i][Size-1-x-y-i][1] += whiteScore
			}
			stones -= b.stones[y][Size-1-x-y]
		}
	}

	for y := 0; y < Size; y++ {
		for x := 0; x < Size; x++ {
			switch b.stones[y][x] {
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
			switch b.stones[y][x] {
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
	return scores
}

func testPlaceScores(stones Stone) (Score, Score) {
	switch stones {
	case 0x05:
		return 360, -360
	case 0x04:
		return 240, -120
	case 0x03:
		return 90, -30
	case 0x02:
		return 24, -6
	case 0x01:
		return 5, -1
	case 0x00:
		return 1, -1
	case 0x10:
		return 1, -5
	case 0x20:
		return 6, -24
	case 0x30:
		return 30, -90
	case 0x40:
		return 120, -240
	case 0x50:
		return 360, -360
	}
	return 0, 0
}

func Test1(t *testing.T) {
	b := NewBoard()
	b.testBoardScores()
	t.Logf("%#v\n", b)

	b.PlaceStone(Black, Size/2, Size/2)
	b.testBoardScores()
	t.Logf("%#v\n", b)

	b.PlaceStone(White, Size/2+1, Size/2)
	scores := b.testBoardScores()
	t.Logf("%#v\n", b)
	for y := 0; y < Size; y++ {
		for x := 0; x < Size; x++ {
			if b.scores[y][x] != scores[y][x] {
				t.Logf("x=%d y=%d expected=%v got%v\n", x, y, scores[y][x], b.scores[y][x])
				t.Fail()
			}
		}
	}
}

func Test2(t *testing.T) {
}

func Test3(t *testing.T) {
}

func Test4(t *testing.T) {
}

func Test5(t *testing.T) {
}
