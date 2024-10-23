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
