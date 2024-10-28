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
			return 6 * coeff, 0, None
		case 0x01:
			return 41 * coeff, -7 * coeff, None
		case 0x02:
			return 232 * coeff, -48 * coeff, None
		case 0x03:
			return 1064 * coeff, -280 * coeff, None
		case 0x04:
			return 0, 0, Black
		case 0x10:
			return -coeff, 7 * coeff, None
		case 0x20:
			return -8 * coeff, 48 * coeff, None
		case 0x30:
			return -56 * coeff, 280 * coeff, None
		}
	} else {
		switch stones {
		case 0x00:
			return 0, -6 * coeff, None
		case 0x01:
			return -7 * coeff, coeff, None
		case 0x02:
			return -48 * coeff, 8 * coeff, None
		case 0x03:
			return -280 * coeff, 56 * coeff, None
		case 0x10:
			return 7 * coeff, -41 * coeff, None
		case 0x20:
			return 48 * coeff, -232 * coeff, None
		case 0x30:
			return 280 * coeff, -1064 * coeff, None
		case 0x40:
			return 0, 0, White
		}
	}
	return 0, 0, None
}
