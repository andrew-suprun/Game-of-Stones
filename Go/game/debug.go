//go:build debug

package game

import (
	"fmt"
)

func (game *Game) validate() {
	failed := false
	values := game.BoardValues()
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
	expected := game.BoardValue()
	if game.value != expected {
		fmt.Printf("Validation failed\nBoard %#v\n", game)
		fmt.Printf("expected=%v got=%v\n", expected, game.value)
		panic("### Validation ###")
	}
}
