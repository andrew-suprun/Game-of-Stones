from game import TGame, TMove
from tree import Tree, Node

from random import seed, random_si64, random_float64
import testing

var __id: Int = 0

@fieldwise_init
struct TestMove(TMove):
    var _id: Int
    var _score: Float32
    var _decisive: Bool

    fn __init__(out self):
        self._id = __id
        self._score = 0
        self._decisive = False

    fn get_score(self) -> Float32:
        return self._score

    fn set_score(mut self, score: Float32):
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

    fn top_moves(mut self, mut move_scores: List[self.Move]):
        ...

    fn play_move(mut self, move: self.Move):
        pass

    fn undo_move(mut self):
        pass


def test_tree():
    var g = TestGame()
    var t = Tree[TestGame, 2]()
    g.play_move(TestMove(0, 0, False))
    _ = t.expand(g)