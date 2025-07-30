from random import seed, random_si64, random_float64
from testing import assert_true
from utils.numerics import inf, neg_inf

from game import TGame, TMove, Score, Decision, undecided
from negamax import Negamax

var __id: Int = 0

@fieldwise_init
struct TestMove(TMove):
    var _id: Int
    var _score: Score
    var _terminal: Bool

    fn __init__(out self):
        self._id = __id
        self._score = 0
        self._terminal = False
        __id += 1

    fn __init__(out self, score: Score, terminal: Bool):
        self._id = __id
        self._score = score
        self._terminal = terminal
        __id += 1

    fn __init__(out self, text: String) raises:
        self._id = __id
        self._score = Score(0)
        self._terminal = undecided
        __id += 1

    fn score(self) -> Score:
        return self._score

    fn is_terminal(self) -> Bool:
        return self._terminal

    fn __str__(self, out r: String):
        r = String.write(self)

    fn __repr__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("<", self._id, "> ", self._score)
        if self._terminal:
            writer.write(" terminal")

struct TestGame(TGame):
    alias Move = TestMove
    alias Score = Score

    fn __init__(out self):
        pass

    fn moves(self) -> List[Self.Move]:
        var n_moves = random_si64(2, 5)
        var moves = List[Self.Move]()
        for _ in range(n_moves):
            var rand = random_si64(0, 16)
            if rand == 0:
                moves.append(TestMove(10, True))
            elif rand == 1 or rand == 2:
                moves.append(TestMove(0, True))
            else:
                moves.append(TestMove(Score(random_float64(-10, 10)), undecided))
        return moves

    fn play_move(mut self, move: self.Move):
        pass

    fn undo_move(mut self, move: self.Move):
        pass

    fn best_move(self) -> TestMove:
        return TestMove(Score(random_float64(-10, 10)), False)

    fn decision(self) -> Decision:
        return undecided

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass

def test_tree():
    seed(4)
    var g = TestGame()
    var t = Negamax[TestGame]()
    var score = t.expand(g, 3)
    print("T: score", score)
    print("T: best move", t.best_move)
    assert_true(String(t.best_move) == "<5> 0.13071215")
    assert_true(String(score) == "4.9088035")
