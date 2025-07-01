from random import seed, random_si64, random_float64
from testing import assert_true
from utils.numerics import inf, neg_inf

from game import TGame, TMove, Score
from tree import Tree, Node

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

    fn __init__(out self, text: String) raises:
        self._id = __id
        self._score = 0
        self._decisive = False
        __id += 1

    fn score(self) -> Score:
        return self._score

    fn setscore(mut self, score: Score):
        self._score = score

    fn isdecisive(self) -> Bool:
        return self._decisive

    fn set_decisive(mut self):
        self._decisive = True

    fn __str__(self, out r: String):
        r = String.write(self)

    fn __repr__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("<", self._id, ">")


struct TestGame(TGame, Writable):
    alias Move = TestMove

    fn __init__(out self):
        pass

    fn moves(self) -> List[self.Move]:
        var n_moves = random_si64(2, 5)
        var moves = List[self.Move]()
        for _ in range(n_moves):
            var move = TestMove()
            move._score = Score(Float32(random_si64(-10, 10)))
            if move._id > 28:
                move._decisive = True
                var rand = random_si64(0, 8)
                if rand == 0:
                    move._score = inf[DType.float32]()
                elif rand == 1:
                    move._score = neg_inf[DType.float32]()
                elif rand == 2:
                    move._score = -0.0
            moves.append(move)
        return moves

    fn play_move(mut self, move: self.Move):
        pass

    fn decision(self) -> StaticString:
        return "no-decision"

    fn write_to[W: Writer](self, mut writer: W):
        pass

def test_tree():
    seed(2)
    var g = TestGame()
    var t = Tree[TestGame, 2]()
    for _ in range(5):
        _ = t.expand(g)
    print(t)
    assert_true(t.root.move.score().value() == -2)
    assert_true(False)
