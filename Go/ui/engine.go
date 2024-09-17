package main

func runEngine(stateChan chan *gameState) {
	// game := connect6.NewGame()
	// root := tree.NewTree[connect6.Move](game, 20)
	// blackMove := game.MakeMove(9, 9, 9, 9)
	// whiteMove := game.MakeMove(8, 9, 10, 9)
	state := <-stateChan
	state.cells[9][9] = stateBlack
	state.cells[8][8] = stateWhite
	state.cells[10][8] = stateWhite
	stateChan <- state
}
