from random import seed, random_si64, random_float64
from testing import assert_true
from utils.numerics import inf, neg_inf
from hashlib.hasher import Hasher

from game import TGame, TMove, Score, MoveScore, Decision, undecided
from mcts import MCTS

@fieldwise_init
struct TestMove(TMove):
    var _id: Int

    fn __init__(out self):
        self._id = 0

    fn __init__(out self, text: StringSlice) raises:
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

    fn moves(self, max_moves: Int) -> List[MoveScore[TestMove]]:
        var moves = List[MoveScore[TestMove]]()
        var n_moves = random_si64(2, 5)
        var id = self.move_id
        for _ in range(n_moves):
            var rand = random_si64(0, 12)
            if rand == 0:
                moves.append(MoveScore(TestMove(id), 10, True))
            elif rand == 1:
                moves.append(MoveScore(TestMove(id), 0, True))
            else:
                moves.append(MoveScore(TestMove(id), Score(random_float64(-10, 10)), False))
            id += 1
        return moves

    fn play_move(mut self, move: self.Move):
        self.move_id *= 10

    fn decision(self) -> Decision:
        return undecided

    fn hash(self) -> Int:
        return 0

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass

def test_tree():
    seed(0)
    var g = TestGame()
    var t = MCTS[TestGame, 10, 10](Score(0))
    for i in range(20):
        var done = t.expand(g)
        if done:
            print("break", i)
            break
    print(t)
    print(t.best_child().move, t.best_child().score, t.best_child().decisive)
    assert_true(String(t.best_child().move) == "<2>")
    assert_true(String(t.best_child().score) == "2.3809257")
    assert_true(t.best_child().decisive == False)
