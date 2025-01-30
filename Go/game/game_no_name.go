//go:build !connect6 && !gomoku

package game

const (
	WinValue   = 0
	maxStones  = 0
	maxStones1 = 0
)

var gameValues = [2][64][2]int16{}
var stoneValues = [64][2]int16{}
var stoneValue = [64]int16{}
