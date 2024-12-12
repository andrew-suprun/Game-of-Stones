//go:build debug

package board

import (
	"fmt"
)

const debug = true

func (b *Board) Validate() {
	failed := false
	scores := b.debugBoardScores()
	for y := 0; y < Size; y++ {
		for x := 0; x < Size; x++ {
			if b.stones[y][x] == None && b.scores[y][x] != scores[y][x] {
				fmt.Printf("x=%d y=%d expected=%v got%v\n", x, y, scores[y][x], b.scores[y][x])
				failed = true
			}
		}
	}
	if failed {
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
		fmt.Printf("%#v\n", b)
		panic("### Validation ###")
	}
}

func (b *Board) debugBoardScores() *[Size][Size][2]Score {
	scores := &[Size][Size][2]Score{}
	for y := 0; y < Size; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.stones[y][x]
		}
		for x := 0; x < Size-maxStones1; x++ {
			stones += b.stones[y][x+maxStones1]
			blackScore, whiteScore := debugScoreStones(stones)
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
			blackScore, whiteScore := debugScoreStones(stones)
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
			blackScore, whiteScore := debugScoreStones(stones)
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
			blackScore, whiteScore := debugScoreStones(stones)
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
			blackScore, whiteScore := debugScoreStones(stones)
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
			blackScore, whiteScore := debugScoreStones(stones)
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
