package main

import (
	"fmt"
	"game_of_stones/board"
	"math/rand"
)

const mid = board.Size / 2

func main() {
	black, white := 0, 0
	for range 100 {
		switch run() {
		case board.Black:
			black++
		case board.White:
			white++
		}
		fmt.Println("black", black, "white", white)
	}
}

func run() board.Stone {
	b := board.MakeBoard()
	b.PlaceStone(board.Black, mid, mid)
	x, y := mid, mid
	for x == mid && y == mid {
		x = mid - 1 + rand.Intn(3)
		y = mid - 1 + rand.Intn(3)
	}
	b.PlaceStone(board.White, x, y)

	x = mid + rand.Intn(2)*6 - 3
	y = mid + rand.Intn(7) - 3
	if rand.Intn(2) == 0 {
		x, y = y, x
	}
	b.PlaceStone(board.Black, x, y)

	turn := board.White
	for {
		x, y := findBestMove(&b, turn)
		fmt.Println(turn, x, y)
		winner := b.PlaceStone(turn, x, y)
		if winner != board.None {
			fmt.Println("Winner", winner)
			return winner
		}
		if turn == board.Black {
			turn = board.White
		} else {
			turn = board.Black
		}
		fmt.Printf("%#v", &b)
	}
}

func findBestMove(b *board.Board, turn board.Stone) (xx, yy int) {
	d := 1
	var bestScore board.Score
	for y := 0; y < board.Size; y++ {
		for x := 0; x < board.Size; x++ {
			if b.Stone(x, y) != board.None {
				continue
			}
			if bestScore == b.Score(turn, x, y) {
				if rand.Intn(d) == 0 {
					// fmt.Println("use:  d", d, "x", x, "y", y, "score", bestScore)
					xx, yy, bestScore = x, y, b.Score(turn, x, y)
					d++
				} else {
					// fmt.Println("skip: d", d, "x", x, "y", y, "score", bestScore)
				}
			} else {
				if turn == board.Black {
					if bestScore < b.Score(board.Black, x, y) {
						xx, yy, bestScore = x, y, b.Score(board.Black, x, y)
						d = 1
					}
				} else {
					if bestScore > b.Score(board.White, x, y) {
						xx, yy, bestScore = x, y, b.Score(board.White, x, y)
						d = 1
					}
				}
			}
		}
	}
	return xx, yy
}
