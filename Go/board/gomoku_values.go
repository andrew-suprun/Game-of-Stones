// Code generated by 'go generate game_of_stones/...'. DO NOT EDIT.

//go:build gomoku

package board

const (
	maxStones = 5
	WinValue  = 5000
)

func valueStones(stone, stones Stone) (float32, float32) {
	if stone == Black {
		switch stones {
		case 0x00:
			return 2, 0
		case 0x01:
			return 5, -3
		case 0x02:
			return 4, -8
		case 0x03:
			return 9964, -12
		case 0x10:
			return -1, 3
		case 0x20:
			return -4, 8
		case 0x30:
			return -12, 12
		}
	} else {
		switch stones {
		case 0x00:
			return 0, -2
		case 0x01:
			return -3, 1
		case 0x02:
			return -8, 4
		case 0x03:
			return -12, 12
		case 0x10:
			return 3, -5
		case 0x20:
			return 8, -4
		case 0x30:
			return 12, -9964
		}
	}
	return 0, 0
}
