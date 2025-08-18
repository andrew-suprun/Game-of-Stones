from random import seed, random_si64, random_float64
from testing import assert_true, assert_false
from hashlib.hasher import Hasher

from score import Score, win, draw, str_score
from game import TGame, TMove, MoveScore
from mcts import Mcts


@fieldwise_init
struct TestMove(TMove):
    var _id: Int

    fn __init__(out self):
        self._id = 0

    fn __init__(out self, text: String) raises:
        self._id = 0

    fn __eq__(self, other: Self) -> Bool:
        return self._id == other._id

    fn __ne__(self, other: Self) -> Bool:
        return self._id != other._id

    fn __hash__[H: Hasher](self, mut hasher: H):
        hasher.update(self._id)

    fn __str__(self, out r: String):
        r = String.write(self)

    fn __repr__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("<", self._id, ">")


struct TestGame(TGame):
    alias Move = TestMove
    alias Score = Score

    var move_id: Int

    fn __init__(out self):
        self.move_id = 1

    fn __copyinit__(out self, other: Self, /):
        self.move_id = other.move_id

    fn copy(self) -> Self:
        return self

    fn moves(self, max_moves: Int) -> List[MoveScore[TestMove]]:
        var moves = List[MoveScore[TestMove]]()
        var n_moves = random_si64(2, 5)
        var id = self.move_id
        for _ in range(n_moves):
            var rand = random_si64(0, 12)
            if rand == 0:
                moves.append(MoveScore(TestMove(id), win))
            elif rand == 1:
                moves.append(MoveScore(TestMove(id), draw))
            else:
                moves.append(MoveScore(TestMove(id), Score(random_float64(-10, 10))))
            id += 1
        return moves

    fn play_move(mut self, move: self.Move) -> Score:
        self.move_id *= 10
        return 0

    fn hash(self) -> Int:
        return 0

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass


def test_tree():
    seed(0)
    var g = TestGame()
    var t = Mcts[TestGame, 10, 10]()
    for i in range(20):
        var done = t.expand(g)
        if done:
            print("break", i)
            break
    print(t)
    print(t._best_child().move)
    assert_true(String(t._best_child().move) == "<2> 2.3809257")
