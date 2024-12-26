// Code generated by 'go generate game_of_stones/gen'. DO NOT EDIT.

//go:build connect6

package board

const (
	maxStones      = 6
	WinValue float32 = 5000
)

func valueStones(stone, stones Stone) (float32, float32) {
	if stone == Black {
		switch stones {
		case 0x00:
			return 3, 0
		case 0x01:
			return 11, -4
		case 0x02:
			return 25, -15
		case 0x03:
			return 20, -40
		case 0x04:
			return 9820, -60
		case 0x10:
			return -1, 4
		case 0x20:
			return -5, 15
		case 0x30:
			return -20, 40
		case 0x40:
			return -60, 60
		}
	} else {
		switch stones {
		case 0x00:
			return 0, -3
		case 0x01:
			return -4, 1
		case 0x02:
			return -15, 5
		case 0x03:
			return -40, 20
		case 0x04:
			return -60, 60
		case 0x10:
			return 4, -11
		case 0x20:
			return 15, -25
		case 0x30:
			return 40, -20
		case 0x40:
			return 60, -9820
		}
	}
	return 0, 0
}