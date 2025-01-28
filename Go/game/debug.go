//go:build debug

package game

import (
	"fmt"
)

func (game *Game) validate() {
	failed := false
	values := game.debugBoardValues()
	for y := 0; y < Size; y++ {
		for x := 0; x < Size; x++ {
			if game.stones[y][x] == None && game.values[y][x] != values[y][x] {
				fmt.Printf("x=%d y=%d expected=%v got%v\n", x, y, values[y][x], game.values[y][x])
				failed = true
			}
		}
	}
	if failed {
		for y := 0; y < Size; y++ {
			for x := 0; x < Size; x++ {
				switch game.stones[y][x] {
				case Black:
					fmt.Print("     X")
				case White:
					fmt.Print("     O")
				case None:
					fmt.Printf("%6d", values[y][x][0])
				}
			}
			fmt.Println()
		}
		fmt.Println()
		for y := 0; y < Size; y++ {
			for x := 0; x < Size; x++ {
				switch game.stones[y][x] {
				case Black:
					fmt.Print("     X")
				case White:
					fmt.Print("     O")
				case None:
					fmt.Printf("%6d", values[y][x][1])
				}
			}
			fmt.Println()
		}
		fmt.Printf("Validation failed\nBoard %#v\n", game)
		panic("### Validation ###")
	}
	expected := game.debugBoardValue()
	if game.value != expected {
		fmt.Printf("Validation failed\nBoard %#v\n", game)
		fmt.Printf("expected=%v got=%v\n", expected, game.value)
		panic("### Validation ###")
	}
}

func (game *Game) debugBoardValues() *[Size][Size][2]int16 {
	values := &[Size][Size][2]int16{}
	for y := int8(0); y < Size; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y][x]
		}
		for x := int8(0); x < Size-game.maxStones1; x++ {
			stones += game.stones[y][x+game.maxStones1]
			bwValues := debugStoneValues[stones]
			// blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y][x+i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[y][x]
		}
	}

	for x := int8(0); x < Size; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x]
		}
		for y := int8(0); y < Size-game.maxStones1; y++ {
			stones += game.stones[y+game.maxStones1][x]
			bwValues := debugStoneValues[stones]
			// blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][x]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[y][x]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y+x][x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][x+game.maxStones1]
			bwValues := debugStoneValues[stones]
			// blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[x+y+i][x+i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[x+y][x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x+y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][x+y+game.maxStones1]
			bwValues := debugStoneValues[stones]
			// blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][x+y+i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[y][x+y]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[x+y][Size-1-x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][Size-1-x-game.maxStones1]
			bwValues := debugStoneValues[stones]
			// blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[x+y+i][Size-1-x-i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[x+y][Size-1-x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][Size-1-x-y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][Size-1-game.maxStones1-x-y]
			bwValues := debugStoneValues[stones]
			// blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][Size-1-x-y-i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[y][Size-1-x-y]
		}
	}

	return values
}

func (game *Game) debugBoardValue() int16 {
	result := int16(0)
	for y := int8(0); y < Size; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y][x]
		}
		for x := int8(0); x < Size-game.maxStones1; x++ {
			stones += game.stones[y][x+game.maxStones1]
			// result += game.debugStonesValue(stones)
			result += debugStoneValue[stones]
			stones -= game.stones[y][x]
		}
	}

	for x := int8(0); x < Size; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x]
		}
		for y := int8(0); y < Size-game.maxStones1; y++ {
			stones += game.stones[y+game.maxStones1][x]
			// result += game.debugStonesValue(stones)
			result += debugStoneValue[stones]
			stones -= game.stones[y][x]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y+x][x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][x+game.maxStones1]
			// result += game.debugStonesValue(stones)
			result += debugStoneValue[stones]
			stones -= game.stones[x+y][x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x+y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][x+y+game.maxStones1]
			// result += game.debugStonesValue(stones)
			result += debugStoneValue[stones]
			stones -= game.stones[y][x+y]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[x+y][Size-1-x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][Size-1-x-game.maxStones1]
			// result += game.debugStonesValue(stones)
			result += debugStoneValue[stones]
			stones -= game.stones[x+y][Size-1-x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][Size-1-x-y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][Size-1-game.maxStones1-x-y]
			// result += game.debugStonesValue(stones)
			result += debugStoneValue[stones]
			stones -= game.stones[y][Size-1-x-y]
		}
	}

	return result
}
