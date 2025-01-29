//go:build gomoku

package game

import . "game_of_stones/common"

const GameName = "gomoku"

func (game *Game) TopMoves(moves *[]MoveValue[Move]) {
	game.topPlaces()
	hasDraw := false
	for _, place := range game.places {
		value := game.values[place.Y][place.X][game.turn]
		if value >= WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MoveValue[Move]{
				Move:     Move{P1: place, P2: place},
				Value:    WinValue,
				Decision: FirstWin}
			return
		} else if value <= -WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MoveValue[Move]{
				Move:     Move{place, place},
				Value:    -WinValue,
				Decision: SecondWin}
			return
		}

		if value != 0 {
			*moves = append(*moves, MoveValue[Move]{
				Move:     Move{place, place},
				Value:    game.value + value/2,
				Decision: NoDecision,
			})
		} else if !hasDraw {
			*moves = append(*moves, MoveValue[Move]{
				Move:     Move{place, place},
				Value:    0,
				Decision: Draw,
			})
			hasDraw = true
		}
	}
}
