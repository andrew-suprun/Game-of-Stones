// Code generated by 'go generate game_of_stones/...'. DO NOT EDIT.

//go:build connect6

package game

const (
	maxStones = 6
	maxStones1 = 5
	WinValue  = 500
)

var gameValues = [2][64][2]int16{
	{ // turn = First
		{3, 0}, {11, -4}, {25, -15}, {20, -40}, {820, -60}, {-880, -880}, {0, 0}, {0, 0}, 
		{-1, 4}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{-5, 15}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{-20, 40}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{-60, 60}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{-120, 880}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
	},
	{ // turn = Second
		{0, -3}, {-4, 1}, {-15, 5}, {-40, 20}, {-60, 60}, {-880, 120}, {0, 0}, {0, 0}, 
		{4, -11}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{15, -25}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{40, -20}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{60, -820}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{880, 880}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
		{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
	},
}

var debugStoneValues = [64][2]int16{
	{1, -1}, {4, -1}, {15, -5}, {40, -20}, {60, -60}, {880, -120}, {0, -1000}, {0, 0}, 
	{1, -4}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
	{5, -15}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
	{20, -40}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
	{60, -60}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
	{120, -880}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
	{1000, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
	{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, 
}

var debugStoneValue = [64]int16{
	0, 1, 5, 20, 60, 120, 1000, 0, 
	-1, 0, 0, 0, 0, 0, 0, 0, 
	-5, 0, 0, 0, 0, 0, 0, 0, 
	-20, 0, 0, 0, 0, 0, 0, 0, 
	-60, 0, 0, 0, 0, 0, 0, 0, 
	-120, 0, 0, 0, 0, 0, 0, 0, 
	-1000, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
}

