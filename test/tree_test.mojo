from random import seed, random_si64, random_float64
from testing import assert_true
from utils.numerics import inf, neg_inf

from score import Score
from game import TGame, TMove
from tree import Tree, Node

var __id: Int = 0

@fieldwise_init
struct TestMove(TMove):
    var _id: Int
    var _score: Score

    fn __init__(out self):
        self._id = __id
        self._score = Score(0)
        __id += 1

    fn __init__(out self, text: String) raises:
        self._id = __id
        self._score = Score(0)
        __id += 1

    fn __str__(self, out r: String):
        r = String.write(self)

    fn __repr__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("<", self._id, ">")


struct TestGame(TGame, Writable):
    alias Move = TestMove
    alias Score = Score

    fn __init__(out self):
        pass

    fn moves(self) -> List[(Self.Move, Score)]:
        var n_moves = random_si64(2, 5)
        var moves = List[(Self.Move, Score)]()
        for _ in range(n_moves):
            var rand = random_si64(0, 8)
            if __id >= 22 and __id <= 23:
                moves.append((TestMove(), Score.loss()))
            elif __id >= 35 and __id <= 37:
                moves.append((TestMove(), Score.loss()))
            elif rand == 0:
                moves.append((TestMove(), Score.win()))
            elif rand == 1:
                moves.append((TestMove(), Score.draw()))
            else:
                moves.append((TestMove(), Score(random_float64(-10, 10))))
        return moves

    fn play_move(mut self, move: self.Move):
        pass

    fn decision(self) -> StaticString:
        return "no-decision"

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass

def test_tree():
    seed(6)
    var g = TestGame()
    var t = Tree[TestGame, 10]()
    for i in range(10):
        var done = t.expand(g)
        print(i, done)
        print(t)
        if done:
            break
    assert_true(False)
