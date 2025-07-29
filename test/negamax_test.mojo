from random import seed, random_si64, random_float64
from testing import assert_true
from utils.numerics import inf, neg_inf

from game import TGame, TMove, Score, win, loss, draw
from negamax import Negamax

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


struct TestGame(TGame):
    alias Move = TestMove
    alias Score = Score

    fn __init__(out self):
        pass

    fn moves(self) -> List[(Self.Move, Score)]:
        var n_moves = random_si64(2, 5)
        var moves = List[(Self.Move, Score)]()
        for _ in range(n_moves):
            var rand = random_si64(0, 8)
            if rand == 0:
                var move = TestMove()
                print("\nT: win move:", move, end="")
                moves.append((move, win))
            elif rand == 1:
                var move = TestMove()
                print("\nT: draw move:", move, end="")
                moves.append((move, draw))
            else:
                moves.append((TestMove(), Score(random_float64(-10, 10))))
        return moves

    fn play_move(mut self, move: self.Move):
        pass

    fn undo_move(mut self, move: self.Move):
        pass

    fn best_score(self) -> Score:
        var score = Score(random_float64(-10, 10))
        return score

    fn decision(self) -> StaticString:
        return "no-decision"

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass

def test_tree():
    seed(6)
    var g = TestGame()
    var t = Negamax[TestGame]()
    var score = t.expand(g, 3)
    print("T: score", score)
    print("T: best move", t.best_move)
    assert_true(String(t.best_move) == "<1>")
    assert_true(abs(score - 7.3030324) < 0.0000001)
    assert_true(False)
