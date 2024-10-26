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

func scoreStones(stone, stones Stone, coeff Score) (Score, Score, Stone) {
	if stone == Black {
		switch stones {
		case 0x00:
			return 4 * coeff, 0 * coeff, None
		case 0x01:
			return 19 * coeff, -5 * coeff, None
		case 0x02:
			return 66 * coeff, -24 * coeff, None
		case 0x03:
			return 150 * coeff, -90 * coeff, None
		case 0x04:
			return 0, 0, Black
		case 0x10:
			return -1 * coeff, 5 * coeff, None
		case 0x20:
			return -6 * coeff, 24 * coeff, None
		case 0x30:
			return -30 * coeff, 90 * coeff, None
		}
	} else {
		switch stones {
		case 0x00:
			return 0 * coeff, -4 * coeff, None
		case 0x01:
			return -5 * coeff, 1 * coeff, None
		case 0x02:
			return -24 * coeff, 6 * coeff, None
		case 0x03:
			return -90 * coeff, 30 * coeff, None
		case 0x10:
			return 5 * coeff, -19 * coeff, None
		case 0x20:
			return 24 * coeff, -66 * coeff, None
		case 0x30:
			return 90 * coeff, -150 * coeff, None
		case 0x40:
			return 0, 0, White
		}
	}
	return 0, 0, None
}
