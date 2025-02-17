from game import Game
from tree import Tree, Node
import value

from random import seed, random_si64, random_float64
import testing


var move_id: Int = 0


@value
struct TestMove(EqualityComparableCollectionElement):
    var id: Int

    @implicit
    fn __init__(out self, id: Int):
        self.id = id

    fn __eq__(self, other: Self) -> Bool:
        return self.id == other.id

    fn __ne__(self, other: Self) -> Bool:
        return self.id != other.id

struct TestGame(Game):
    alias Move = TestMove

    fn __init__(out self):
        pass

    fn copy(self) -> Self:
        return TestGame[M]()

    fn top_moves(self, mut moves: List[Self.Move], mut values: List[Float32]):
        moves.clear()
        values.clear()
        if random_si64(0, 8) == 0:
            move_id += 1
            moves.append(TestMove(move_id))
            values.append(value.win())
            return
        
        var n_moves = random_si64(2, 5):
        for _ in range(n_moves):
            move_id += 1
            moves.append(TestMove(move_id))
            if random_si64(0, 8) == 0:
                values.append(value.draw())
            else:
                values.append(random_float64(-1, 1))

        

    fn play_move(mut self, move: Self.Move):
        pass


alias TG = TestGame


def test_tree():
    seed(1)
    var g = TG()
    var t = Tree[TG](1)
