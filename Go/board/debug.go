//go:build debug

package board

import (
	"fmt"
)

func (b *Board) Validate() {
	failed := false
	values := b.debugBoardValues()
	for y := 0; y < Size; y++ {
		for x := 0; x < Size; x++ {
			if b.stones[y][x] == None && b.values[y][x] != values[y][x] {
				fmt.Printf("x=%d y=%d expected=%v got%v\n", x, y, values[y][x], b.values[y][x])
				failed = true
			}
		}
	}
	if failed {
		for y := 0; y < Size; y++ {
			for x := 0; x < Size; x++ {
				switch b.stones[y][x] {
				case Black:
					fmt.Print("     X")
				case White:
					fmt.Print("     O")
				case None:
					fmt.Printf("%6.0f", values[y][x][0])
				}
			}
			fmt.Println()
		}
		fmt.Println()
		for y := 0; y < Size; y++ {
			for x := 0; x < Size; x++ {
				switch b.stones[y][x] {
				case Black:
					fmt.Print("     X")
				case White:
					fmt.Print("     O")
				case None:
					fmt.Printf("%6.0f", values[y][x][1])
				}
			}
			fmt.Println()
		}
		fmt.Println()
		fmt.Printf("%#v\n", b)
		panic("### Validation ###")
	}
}

func (b *Board) debugBoardValues() *[Size][Size][2]int16 {
	values := &[Size][Size][2]int16{}
	for y := 0; y < Size; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.stones[y][x]
		}
		for x := 0; x < Size-maxStones1; x++ {
			stones += b.stones[y][x+maxStones1]
			blackValue, whiteValue := debugStonesValues(stones)
			for i := 0; i < maxStones; i++ {
				s := &values[y][x+i]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := debugStonesValues(stones)
			for i := 0; i < maxStones; i++ {
				s := &values[y+i][x]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := debugStonesValues(stones)
			for i := 0; i < maxStones; i++ {
				s := &values[x+y+i][x+i]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := debugStonesValues(stones)
			for i := 0; i < maxStones; i++ {
				s := &values[y+i][x+y+i]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := debugStonesValues(stones)
			for i := 0; i < maxStones; i++ {
				s := &values[x+y+i][Size-1-x-i]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := debugStonesValues(stones)
			for i := 0; i < maxStones; i++ {
				s := &values[y+i][Size-1-x-y-i]
				s[0] += blackValue
				s[1] += whiteValue
			}
			stones -= b.stones[y][Size-1-x-y]
		}
	}

	return values
}

func (b *Board) BoardValue() int16 {
	result := int16(0)
	for y := 0; y < Size; y++ {
		stones := Stone(0)
		for x := 0; x < maxStones1; x++ {
			stones += b.stones[y][x]
		}
		for x := 0; x < Size-maxStones1; x++ {
			stones += b.stones[y][x+maxStones1]
			result += debugStonesValue(stones)
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
			result += debugStonesValue(stones)
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
			result += debugStonesValue(stones)
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
			result += debugStonesValue(stones)
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
			result += debugStonesValue(stones)
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
			result += debugStonesValue(stones)
			stones -= b.stones[y][Size-1-x-y]
		}
	}

	return result
}
