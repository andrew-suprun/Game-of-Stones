from random import seed, random_si64, random_float64
from testing import assert_true
from utils.numerics import inf, neg_inf

from game import TGame, TMove, Score, Decision, undecided, win, draw, loss
from negamax import Negamax

var __id: Int = 0

@fieldwise_init
struct TestMove(TMove):
    var _id: Int
    var _score: Score
    var _decision: Decision

    fn __init__(out self):
        self._id = __id
        self._score = 0
        self._decision = undecided
        __id += 1

    fn __init__(out self, score: Score, decision: Decision):
        self._id = __id
        self._score = score
        self._decision = decision
        __id += 1

    fn __init__(out self, text: String) raises:
        self._id = __id
        self._score = Score(0)
        self._decision = undecided
        __id += 1

    fn score(self) -> Score:
        return self._score

    fn set_score(mut self, score: Score):
        self._score = score

    fn decision(self) -> Decision:
        return self._decision

    fn set_decision(mut self, decision: Decision):
        self._decision = decision

    fn __str__(self, out r: String):
        r = String.write(self)

    fn __repr__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("<", self._id, "> ", self._score)
        if self._decision == win:
            writer.write(" win")
        elif self._decision == draw:
            writer.write(" draw")
        if self._decision == loss:
            writer.write(" loss")



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
                moves.append(TestMove(100, win))
            elif rand == 1 or rand == 2:
                moves.append(TestMove(0, draw))
            else:
                moves.append(TestMove(Score(random_float64(-10, 10)), undecided))
        return moves

    fn play_move(mut self, move: self.Move):
        pass

    fn undo_move(mut self, move: self.Move):
        pass

    fn best_score(self) -> Score:
        var score = Score(random_float64(-10, 10))
        return score

    fn decision(self) -> Decision:
        return undecided

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass

def test_tree():
    seed(2)
    var g = TestGame()
    var t = Negamax[TestGame]()
    var score = t.expand(g, 3)
    print("T: score", score)
    print("T: best move", t.best_move)
    assert_true(String(t.best_move) == "<1>")
    assert_true(abs(score - 7.3030324) < 0.0000001)
    assert_true(False)
