from random import seed, random_si64, random_float64
from testing import assert_true
from utils.numerics import inf, neg_inf

import board
from game import TGame, TMove, Decision
from tree import Tree, Node

var __id: Int = 0

@fieldwise_init
struct TestMove(TMove):
    alias Score = board.Score

    var _id: Int
    var _score: Self.Score
    var _decision: Decision

    fn __init__(out self):
        self._id = __id
        self._score = 0
        self._decision = Decision.undecided
        __id += 1

    fn __init__(out self, text: String) raises:
        self._id = __id
        self._score = 0
        self._decision = Decision.undecided
        __id += 1

    fn score(self) -> Self.Score:
        return self._score

    fn setscore(mut self, score: Self.Score):
        self._score = score

    fn decision(self) -> Decision:
        return self._decision

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

    fn moves(self) -> List[Self.Move]:
        var n_moves = random_si64(2, 5)
        var moves = List[Self.Move]()
        for _ in range(n_moves):
            var move = TestMove()
            move._score = Self.Move.Score(Int(random_si64(-10, 10)))
            var rand = random_si64(0, 8)
            if rand == 0:
                move._decision = Decision.win
            elif rand == 1:
                move._decision = Decision.draw
            moves.append(move)
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
    seed(2)
    var g = TestGame()
    var t = Tree[TestGame, 2]()
    for _ in range(10):
        _ = t.expand(g)
    print(t)
    assert_true(t.root.move.score() == -2)
    assert_true(False)
