//go:build !debug

package game

func (game *Game) validate()              {}
func (game *Game) DebugBoardValue() int16 { return 0 }
