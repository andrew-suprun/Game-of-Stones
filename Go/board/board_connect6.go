//go:build !gomoku

package board

const maxStones = 6

func scoreStones(stone, stones Stone) (Score, Score) {
	if stone == Black {
		switch stones {
		case 0x04:
			return 120, -120
		case 0x03:
			return 150, -90
		case 0x02:
			return 66, -24
		case 0x01:
			return 19, -5
		case 0x00:
			return 4, 0
		case 0x10:
			return -1, 5
		case 0x20:
			return -6, 24
		case 0x30:
			return -30, 90
		case 0x40:
			return -120, 120
		}
	} else {
		switch stones {
		case 0x04:
			return -120, 120
		case 0x03:
			return -90, 30
		case 0x02:
			return -24, 6
		case 0x01:
			return -5, 1
		case 0x00:
			return 0, -4
		case 0x10:
			return 5, -19
		case 0x20:
			return 24, -66
		case 0x30:
			return 90, -150
		case 0x40:
			return 120, -120
		}
	}
	return 0, 0
}
