//go:build !gomoku

package board

const maxStones = 6

const (
	s1 = 1
	s2 = 7
	s3 = 7 * 6
	s4 = 7 * 6 * 5
	s5 = 7 * 6 * 5
	s6 = 7 * 6 * 5 * 4
)

var debugBlackScores = [maxStones * maxStones]Score{
	s1, s2 - s1, s3 - s2, s4 - s3, s5 - s4, s6 - s5,
	s1, 0, 0, 0, 0, 0,
	s2, 0, 0, 0, 0, 0,
	s3, 0, 0, 0, 0, 0,
	s4, 0, 0, 0, 0, 0,
	s5, 0, 0, 0, 0, 0,
}

var debugWhiteScores = [maxStones * maxStones]Score{
	-s1, -s1, -s2, -s3, -s5, -s6,
	s1 - s2, 0, 0, 0, 0, 0,
	s2 - s3, 0, 0, 0, 0, 0,
	s3 - s4, 0, 0, 0, 0, 0,
	s4 - s5, 0, 0, 0, 0, 0,
	s5 - s6, 0, 0, 0, 0, 0,
}
