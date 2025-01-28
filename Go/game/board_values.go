package game

func (game *Game) BoardValues() *[Size][Size][2]int16 {
	values := &[Size][Size][2]int16{}
	for y := int8(0); y < Size; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y][x]
		}
		for x := int8(0); x < Size-game.maxStones1; x++ {
			stones += game.stones[y][x+game.maxStones1]
			bwValues := stoneValues[stones]
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y][x+i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[y][x]
		}
	}

	for x := int8(0); x < Size; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x]
		}
		for y := int8(0); y < Size-game.maxStones1; y++ {
			stones += game.stones[y+game.maxStones1][x]
			bwValues := stoneValues[stones]
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][x]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[y][x]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y+x][x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][x+game.maxStones1]
			bwValues := stoneValues[stones]
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[x+y+i][x+i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[x+y][x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x+y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][x+y+game.maxStones1]
			bwValues := stoneValues[stones]
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][x+y+i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[y][x+y]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[x+y][Size-1-x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][Size-1-x-game.maxStones1]
			bwValues := stoneValues[stones]
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[x+y+i][Size-1-x-i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[x+y][Size-1-x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][Size-1-x-y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][Size-1-game.maxStones1-x-y]
			bwValues := stoneValues[stones]
			for i := int8(0); i < game.maxStones; i++ {
				s := &values[y+i][Size-1-x-y-i]
				s[0] += bwValues[0]
				s[1] += bwValues[1]
			}
			stones -= game.stones[y][Size-1-x-y]
		}
	}

	return values
}

func (game *Game) BoardValue() int16 {
	result := int16(0)
	for y := int8(0); y < Size; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y][x]
		}
		for x := int8(0); x < Size-game.maxStones1; x++ {
			stones += game.stones[y][x+game.maxStones1]
			result += stoneValue[stones]
			stones -= game.stones[y][x]
		}
	}

	for x := int8(0); x < Size; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x]
		}
		for y := int8(0); y < Size-game.maxStones1; y++ {
			stones += game.stones[y+game.maxStones1][x]
			result += stoneValue[stones]
			stones -= game.stones[y][x]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y+x][x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][x+game.maxStones1]
			result += stoneValue[stones]
			stones -= game.stones[x+y][x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x+y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][x+y+game.maxStones1]
			result += stoneValue[stones]
			stones -= game.stones[y][x+y]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[x+y][Size-1-x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][Size-1-x-game.maxStones1]
			result += stoneValue[stones]
			stones -= game.stones[x+y][Size-1-x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][Size-1-x-y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][Size-1-game.maxStones1-x-y]
			result += stoneValue[stones]
			stones -= game.stones[y][Size-1-x-y]
		}
	}

	return result
}
