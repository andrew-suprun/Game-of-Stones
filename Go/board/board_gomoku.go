//go:build gomoku

package board

const maxStones = 5

const (
	s1 = 1
	s2 = 6
	s3 = 30
	s4 = 120
	s5 = 360
)

var debugBlackScores = [maxStones * maxStones]Score{
	s1, s2 - s1, s3 - s2, s4 - s3, s5 - s4,
	s1, 0, 0, 0, 0,
	s2, 0, 0, 0, 0,
	s3, 0, 0, 0, 0,
	s4, 0, 0, 0, 0,
}

var debugWhiteScores = [maxStones * maxStones]Score{
	-s1, -s1, -s2, -s3, -s5,
	s1 - s2, 0, 0, 0, 0,
	s2 - s3, 0, 0, 0, 0,
	s3 - s4, 0, 0, 0, 0,
	s4 - s5, 0, 0, 0, 0,
}

func scoreStones(stone, stones Stone) (Score, Score) {
	if stone == Black {
		switch stones {
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
		}
	} else {
		switch stones {
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
		}
	}
	return 0, 0
}
