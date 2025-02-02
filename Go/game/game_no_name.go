//go:build !connect6 && !gomoku

package game

const (
	WinValue   = 500
	maxStones  = 5
	maxStones1 = 4
)

var gameValues = [2][64][2]int16{}
var stoneValues = [64][2]int16{}
var stoneValue = [64]int16{}
