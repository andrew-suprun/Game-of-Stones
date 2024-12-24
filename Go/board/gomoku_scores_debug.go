// Code generated by 'go generate game_of_stones/gen'. DO NOT EDIT.

//go:build gomoku && debug

package board

import "game_of_stones/value"

func debugValueStones(stones Stone) (value.Value, value.Value) {
	switch stones {
	case 0x00:
		return 2, -2
	case 0x01:
		return 14, -2
	case 0x02:
		return 80, -16
	case 0x03:
		return 288, -96
	case 0x04:
		return 100288, -384
	case 0x10:
		return 2, -14
	case 0x20:
		return 16, -80
	case 0x30:
		return 96, -288
	case 0x40:
		return 384, -100288

	}
	return 0, 0
}
