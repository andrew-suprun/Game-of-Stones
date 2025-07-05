from random import seed, random_si64, random_float64
from testing import assert_true
from utils.numerics import inf, neg_inf

from game import TGame, TMove, Decision, win, draw, loss, undecided
from tree import Tree, Node

var __id: Int = 0

@fieldwise_init
struct TestMove(TMove):
    var _id: Int
    var _decision: Decision

    fn __init__(out self):
        self._id = __id
        var r = random_si64(0, 20)
        if r == 0:
            self._decision = win
        elif r == 1 or r == 3:
            self._decision = draw
        else:
            self._decision = undecided
        __id += 1


    fn __init__(out self, text: String) raises:
        self._id = __id
        self._decision = undecided
        __id += 1

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

    fn moves(self) -> List[self.Move]:
        var n_moves = random_si64(2, 5)
        var moves = List[self.Move]()
        for _ in range(n_moves):
            var move = TestMove()
            moves.append(move)
        return moves

    fn play_move(mut self, move: self.Move):
        pass

    fn decision(self) -> Decision:
        return undecided

    fn rollout(self, move: Self.Move) -> Decision:
        var res =  Decision(random_si64(-1, 1))
        return res
        
    fn write_to[W: Writer](self, mut writer: W):
        pass

def test_tree():
    seed(0)
    var g = TestGame()
    var t = Tree[TestGame, 1]()
    for i in range(1, 11):
        var done = t.expand(g)
        print("tree", i)
        print(t)
        if done:
            break
    assert_true(t.root.value == -3)
    assert_true(t.root.n_sims == 17)
