//go:build !debug

package game

func (game *Game) validate() {}

func (game *Game) debugBoardValue() int16 { panic("use -tags=debug") }

func (game *Game) debugBoardValues() *[Size][Size][2]int16 { panic("use -tags=debug") }
