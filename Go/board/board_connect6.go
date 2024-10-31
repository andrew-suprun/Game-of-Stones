//go:build !gomoku

package board

const (
	maxStones = 6
)

func scoreStones(stone, stones Stone) (Score, Score) {
	if stone == Black {
		switch stones {
		case 0x00:
			return 6, 0
		case 0x01:
			return 41, -7
		case 0x02:
			return 232, -48
		case 0x03:
			return 1064, -280
		case 0x04:
			return 20000, -1344
		case 0x10:
			return -1, 7
		case 0x20:
			return -8, 48
		case 0x30:
			return -56, 280
		case 0x40:
			return -336, 1344
		}
	} else {
		switch stones {
		case 0x00:
			return 0, -6
		case 0x01:
			return -7, 1
		case 0x02:
			return -48, 8
		case 0x03:
			return -280, 56
		case 0x04:
			return -1344, 336
		case 0x10:
			return 7, -41
		case 0x20:
			return 48, -232
		case 0x30:
			return 280, -1064
		case 0x40:
			return 1344, -20000
		}
	}
	return 0, 0
}