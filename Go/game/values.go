package game

func (game *Game) valueStones(stones Stone) [2]int16 {
	if game.name == Gomoku {
		if game.stone == Black {
			switch stones {
			case 0x00:
				return [2]int16{2, 0}
			case 0x01:
				return [2]int16{5, -3}
			case 0x02:
				return [2]int16{4, -8}
			case 0x03:
				return [2]int16{9964, -12}
			case 0x10:
				return [2]int16{-1, 3}
			case 0x20:
				return [2]int16{-4, 8}
			case 0x30:
				return [2]int16{-12, 12}
			}
		} else {
			switch stones {
			case 0x00:
				return [2]int16{0, -2}
			case 0x01:
				return [2]int16{-3, 1}
			case 0x02:
				return [2]int16{-8, 4}
			case 0x03:
				return [2]int16{-12, 12}
			case 0x10:
				return [2]int16{3, -5}
			case 0x20:
				return [2]int16{8, -4}
			case 0x30:
				return [2]int16{12, -9964}
			}
		}
		return [2]int16{0, 0}
	} else {
		if game.stone == Black {
			switch stones {
			case 0x00:
				return [2]int16{3, 0}
			case 0x01:
				return [2]int16{11, -4}
			case 0x02:
				return [2]int16{25, -15}
			case 0x03:
				return [2]int16{20, -40}
			case 0x04:
				return [2]int16{9820, -60}
			case 0x10:
				return [2]int16{-1, 4}
			case 0x20:
				return [2]int16{-5, 15}
			case 0x30:
				return [2]int16{-20, 40}
			case 0x40:
				return [2]int16{-60, 60}
			}
		} else {
			switch stones {
			case 0x00:
				return [2]int16{0, -3}
			case 0x01:
				return [2]int16{-4, 1}
			case 0x02:
				return [2]int16{-15, 5}
			case 0x03:
				return [2]int16{-40, 20}
			case 0x04:
				return [2]int16{-60, 60}
			case 0x10:
				return [2]int16{4, -11}
			case 0x20:
				return [2]int16{15, -25}
			case 0x30:
				return [2]int16{40, -20}
			case 0x40:
				return [2]int16{60, -9820}
			}
		}
		return [2]int16{0, 0}
	}
}
