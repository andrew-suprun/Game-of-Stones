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
			blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y][x+i]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][x]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[x+y+i][x+i]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][x+y+i]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[x+y+i][Size-1-x-i]
				s[0] += blackValue
				s[1] += whiteValue
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
			blackValue, whiteValue := game.debugStonesValues(stones)
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][Size-1-x-y-i]
				s[0] += blackValue
				s[1] += whiteValue
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
			result += game.debugStonesValue(stones)
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
			result += game.debugStonesValue(stones)
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
			result += game.debugStonesValue(stones)
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
			result += game.debugStonesValue(stones)
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
			result += game.debugStonesValue(stones)
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
			result += game.debugStonesValue(stones)
			stones -= game.stones[y][Size-1-x-y]
		}
	}

	return result
}

func (game *Game) debugStonesValues(stones Stone) (int16, int16) {
	if game.name == Gomoku {
		switch stones {
		case 0x00:
			return 1, -1
		case 0x01:
			return 3, -1
		case 0x02:
			return 8, -4
		case 0x03:
			return 12, -12
		case 0x04:
			return 9976, -24
		case 0x10:
			return 1, -3
		case 0x20:
			return 4, -8
		case 0x30:
			return 12, -12
		case 0x40:
			return 24, -9976

		}
		return 0, 0
	} else {
		switch stones {
		case 0x00:
			return 1, -1
		case 0x01:
			return 4, -1
		case 0x02:
			return 15, -5
		case 0x03:
			return 40, -20
		case 0x04:
			return 60, -60
		case 0x05:
			return 9880, -120
		case 0x10:
			return 1, -4
		case 0x20:
			return 5, -15
		case 0x30:
			return 20, -40
		case 0x40:
			return 60, -60
		case 0x50:
			return 120, -9880

		}
		return 0, 0
	}
}

func (game *Game) debugStonesValue(stones Stone) int16 {
	if game.name == Gomoku {
		switch stones {
		case 0x01:
			return 1
		case 0x02:
			return 4
		case 0x03:
			return 12
		case 0x04:
			return 24
		case 0x05:
			return 10000
		case 0x10:
			return -1
		case 0x20:
			return -4
		case 0x30:
			return -12
		case 0x40:
			return -24
		case 0x50:
			return -10000

		}
		return 0
	} else {
		switch stones {
		case 0x01:
			return 1
		case 0x02:
			return 5
		case 0x03:
			return 20
		case 0x04:
			return 60
		case 0x05:
			return 120
		case 0x06:
			return 10000
		case 0x10:
			return -1
		case 0x20:
			return -5
		case 0x30:
			return -20
		case 0x40:
			return -60
		case 0x50:
			return -120
		case 0x60:
			return -10000

		}
		return 0
	}
}
