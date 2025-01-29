//go:build connect6

package game

import (
	. "game_of_stones/common"
	"game_of_stones/heap"
)

const GameName = "connect6"

func (game *Game) TopMoves(moves *[]MoveValue[Move]) {
	less := func(a, b MoveValue[Move]) bool {
		return a.Value < b.Value
	}
	if game.stone == White {
		less = func(a, b MoveValue[Move]) bool {
			return a.Value > b.Value
		}
	}

	*moves = (*moves)[:0]
	game.topPlaces()

	if len(game.places) < 2 {
		*moves = append(*moves, MoveValue[Move]{
			Move:     Move{Place{0, 0}, Place{0, 0}},
			Value:    0,
			Decision: Draw,
		})
		return
	}
	gameValue := game.value
	hasDraw := false

	for i, place1 := range game.places {
		value1 := game.values[place1.Y][place1.X][game.turn]

		if value1 >= WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MoveValue[Move]{
				Move:     Move{P1: place1, P2: place1},
				Value:    WinValue,
				Decision: FirstWin}
			return
		} else if value1 < -WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MoveValue[Move]{
				Move:     Move{P1: place1, P2: place1},
				Value:    -WinValue,
				Decision: SecondWin}
			return
		}

		game.placeStone(place1, 1)

		for _, place2 := range game.places[i+1:] {
			value2 := game.values[place2.Y][place2.X][game.turn]

			if value2 >= WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = MoveValue[Move]{
					Move:     Move{P1: place1, P2: place2},
					Value:    WinValue,
					Decision: FirstWin}
				game.placeStone(place1, -1)
				return
			} else if value2 < -WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = MoveValue[Move]{
					Move:     Move{P1: place1, P2: place2},
					Value:    -WinValue,
					Decision: SecondWin}
				game.placeStone(place1, -1)
				return
			}

			value := value1 + value2

			if value == 0 {
				if !hasDraw {
					*moves = append(*moves, MoveValue[Move]{
						Move:     Move{place1, place2},
						Value:    0,
						Decision: Draw,
					})
					hasDraw = true
				}
			} else {
				value = gameValue + value/2 //TODO: Check alternative scoring below:

				// game.placeStone(place2, 1)
				// oppVal := game.oppValue()
				// game.placeStone(place2, -1)
				// value = gameValue + value + oppVal

				move := MoveValue[Move]{
					Move:     Move{place1, place2},
					Value:    value,
					Decision: NoDecision,
				}
				heap.Add(move, moves, less)
			}
		}

		game.placeStone(place1, -1)
	}
}

func (game *Game) oppValue() int16 {
	oppTurn := First
	if game.stone == Black {
		oppTurn = Second
	}
	if oppTurn == Second {
		var oppVal int16 = WinValue
		for y := int8(0); y < Size; y++ {
			for x := int8(0); x < Size; x++ {
				if game.stones[y][x] != None {
					continue
				}
				v := game.values[y][x][1]
				oppVal = min(oppVal, v)
			}
		}
		return oppVal
	} else {
		var oppVal int16 = -WinValue
		for y := int8(0); y < Size; y++ {
			for x := int8(0); x < Size; x++ {
				if game.stones[y][x] != None {
					continue
				}
				v := game.values[y][x][0]
				oppVal = max(oppVal, v)
			}
		}
		return oppVal
	}
}
