from game import Game, Move
from tree import Tree, Node
import scores

from random import seed, random_si64, random_float64
import testing


struct TestGame(Game):
    fn __init__(out self):
        pass

    fn copy(self) -> Self:
        return TestGame()

    fn top_moves(self, mut moves: List[Move], mut values: List[Float32]):
        moves.clear()
        values.clear()
        if random_si64(0, 8) == 0:
            moves.append(random_move())
            values.append(scores.win)
            return

        var n_moves = random_si64(2, 5)
        for _ in range(n_moves):
            moves.append(random_move())
            if random_si64(0, 8) == 0:
                values.append(scores.draw)
            else:
                values.append(Float32(random_float64(-1, 1)))

    fn play_move(mut self, move: Move):
        pass


fn random_move() -> game.Move:
    return game.Move(
        Int(random_si64(0, 18)),
        Int(random_si64(0, 18)),
        Int(random_si64(0, 18)),
        Int(random_si64(0, 18)),
    )


def test_tree():
    print("start")
    seed(1)
    var g = TestGame()
    var t = Tree[TestGame](1)
    t.expand(g)
    print(t)
