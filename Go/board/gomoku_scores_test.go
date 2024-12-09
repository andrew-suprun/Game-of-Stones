// Code generated by 'go generate game_of_stones/gen'. DO NOT EDIT.

//go:build gomoku

package board

func testScoreStones(stones Stone) (Score, Score) {
	switch stones {
	case 0x00:
		return 1, -1
	case 0x01:
		return 7, -1
	case 0x02:
		return 56, -8
	case 0x03:
		return 384, -64
	case 0x04:
		return 2240, -448
	case 0x10:
		return 1, -7
	case 0x20:
		return 8, -56
	case 0x30:
		return 64, -384
	case 0x40:
		return 448, -2240

	}
	return 0, 0
}
