// Code generated by 'go generate game_of_stones/gen'. DO NOT EDIT.

//go:build gomoku && debug

package board

func debugValueStones(stones Stone) (float32, float32) {
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
}