//go:build !gomoku

package board

const maxStones = 6

func scoreStones(stone, stones Stone, coeff Score) (Score, Score) {
	return 0, 0
}
