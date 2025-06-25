from random import seed, random_si64, random_float64
from testing import assert_true

import score
from game import TGame, TMove
from tree import Tree, Node

var __id: Int = 0

@fieldwise_init
struct TestMove(TMove):
    alias Score = score.Score

    var _id: Int
    var _score: Self.Score
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

    fn score(self) -> Self.Score:
        return self._score

    fn set_score(mut self, score: Self.Score):
        self._score = score

    fn is_decisive(self) -> Bool:
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
            move._score = score.Score(Float32(random_si64(-10, 10)))
            move._decisive = random_si64(0, 10) % 10 == 0
            if move._id > 28 and move._id < 40:
                move._decisive = True
                move._score = 0.5
                if move._id == 37:
                    move._decisive = True
                    move._score = score.Score.loss()
                elif move._id == 38:
                    move._decisive = False
                    move._score = -5
            moves.append(move)
        return moves

    fn play_move(mut self, move: self.Move):
        pass

    fn decision(self) -> StaticString:
        return "no-decision"

    fn write_to[W: Writer](self, mut writer: W):
        pass

def test_tree():
    seed(0)
    var g = TestGame()
    var t = Tree[TestGame, 2]()
    for _ in range(5):
        _ = t.expand(g)
    print(t)
    assert_true(t.root.move.score().value() == -2)
