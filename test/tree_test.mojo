from game import TGame, TMove
from tree import Tree, Node

from random import seed, random_si64, random_float64
from testing import assert_true

var __id: Int = 0

@fieldwise_init
struct TestMove(TMove):
    var _id: Int
    var _score: Score
    var _decisive: Bool

    fn __init__(out self):
        self._id = __id
        self._score = 0
        self._decisive = False
        __id += 1

    fn score(self) -> Score:
        return self._score

    fn set_score(mut self, score: Score):
        self._score = score

    fn is_decisive(self) -> Bool:
        return self._decisive

    fn set_decisive(mut self):
        self._decisive = True

    fn __str__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self._id, " ", self._score, " ", self._decisive)


struct TestGame(TGame):
    alias Move = TestMove

    fn __init__(out self):
        pass

    fn name(self) -> String:
        return "test game"

    fn top_moves(mut self, mut moves: List[self.Move]):
        var n_moves = random_si64(2, 5)
        moves.clear()
        for _ in range(n_moves):
            var move = TestMove()
            move._score = Score(random_si64(-10, 10))
            move._decisive = random_si64(0, 10) % 10 == 0
            moves.append(move)

    fn play_move(mut self, move: self.Move):
        pass

    fn undo_move(mut self):
        pass


def test_tree():
    seed(0)
    var g = TestGame()
    var t = Tree[TestGame, 2]()
    g.play_move(TestMove(0, 0, False))
    print(t)
    _ = t.expand(g)
    _ = t.expand(g)
    print(t)
    assert_true(False)