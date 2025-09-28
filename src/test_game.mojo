import random
from hashlib.hasher import Hasher

from score import Score
from game import TGame, TMove, MoveScore


@fieldwise_init
struct TestMove(TMove):
    var _id: Int

    fn __init__(out self):
        self._id = 0

    fn __init__(out self, text: String) raises:
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
        writer.write("(", self._id, ")")


alias zero_move = MoveScore(TestMove(), Score(0))


# struct TestGame(TGame):
struct TestGame(TGame):
    alias Move = TestMove

    var _moves: Dict[Int, MoveScore[TestMove]]
    var _current_id: Int
    var _hash: UInt64

    fn __init__(out self):
        self = Self(5, 0)

    fn __init__(out self, depth: Int, seed: Int):
        random.seed(seed)
        self._current_id = 0
        self._hash = 0
        self._moves = Dict[Int, MoveScore[TestMove]]()
        self._moves[0] = MoveScore(TestMove(0), Score())
        self._init_moves(0, depth)

    fn _init_moves(mut self, var id: Int, depth: Int):
        id *= 10
        var n_children = 1 if depth == 0 else Int(random.random_si64(1, 2 + depth))
        for _ in range(n_children):
            id += 1
            var rand = random.random_si64(0, 12)
            if rand == 0 and depth < 3:
                self._moves[id] = MoveScore(TestMove(id), Score.win())
            elif rand == 1 and depth < 3:
                self._moves[id] = MoveScore(TestMove(id), Score.draw())
            else:
                self._moves[id] = MoveScore(TestMove(id), Score(random.random_float64(-10, 10)))
                if depth > 0:
                    self._init_moves(id, depth - 1)

    fn _current_move(self) -> MoveScore[TestMove]:
        return self._moves.get(self._current_id, zero_move)

    fn score(self) -> Score:
        return self._current_move().score

    fn move(self) -> MoveScore[TestMove]:
        var result = MoveScore[TestMove](TestMove(), Score.loss())
        for move in self.moves():
            if result.score < move.score:
                result = move
        return result

    fn moves(self) -> List[MoveScore[TestMove]]:
        var moves = List[MoveScore[TestMove]]()
        var id = self._current_id * 10
        try:
            while True:
                id += 1
                moves.append(self._moves[id])
        except:
            pass
        return moves^

    fn play_move(mut self, move: self.Move) -> Score:
        self._current_id = move._id
        self._hash += hash(move._id)
        return self._current_move().score

    fn undo_move(mut self, move: self.Move):
        self._current_id = move._id // 10
        self._hash -= hash(move._id)

    fn hash(self) -> Int:
        return Int(self._hash)

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, zero_move, 0)

    fn write_to[W: Writer](self, mut writer: W, move: MoveScore[TestMove], depth: Int):
        writer.write("|   " * depth, move, "\n")

        var child_id = move.move._id * 10
        try:
            while True:
                child_id += 1
                var child = self._moves[child_id]
                if child.move._id > 0:  # unnecessary check to quite LSP warning
                    self.write_to(writer, child, depth + 1)
        except:
            return


fn simple_negamax[G: TGame](mut game: G, depth: Int, max_depth: Int) -> Score:
    @parameter
    fn greater(a: MoveScore[G.Move], b: MoveScore[G.Move]) -> Bool:
        return a.score > b.score

    var score = Score.loss()
    var moves = game.moves()
    sort[greater](moves)
    for move in moves:
        print("|   " * depth, depth, "> ", move.move, sep="")
        var new_score = move.score
        if depth < max_depth and not new_score.is_decisive():
            _ = game.play_move(move.move)
            new_score = -simple_negamax(game, depth + 1, max_depth)
            game.undo_move(move.move)
        score = max(score, new_score)
        print("|   " * depth, depth, "< ", move.move, "; score ", score, sep="")
    return score


from compile import get_type_name
from connect6 import Connect6
from negamax import Negamax
from negamax_zero import Node
from time import perf_counter_ns

alias Game = Connect6[size=19, max_moves=8, max_places=6, max_plies=100]
alias max_depth = 3


fn main() raises:
    var game = Game()
    _ = game.play_move("j10")
    _ = game.play_move("i9-i10")

    # var tree1 = NegamaxZero[Game]()
    # var tree2 = Negamax[Game]()

    var root = Node[Game](MoveScore[Game.Move](Game.Move(), Score()))
    start = perf_counter_ns()
    var complete = root.search(game, Score.loss(), Score.win(), 0, max_depth, start + 1_000_000_000)

    # start = perf_counter_ns()
    # tree2._deadline = start + 10_000_000_000
    # _ = tree2._search(game, Score.loss(), Score.win(), 0, max_depth)
    # print("==== nmax:", tree2._best_move, "time:", Float64(perf_counter_ns() - start) / 1_000_000_000)
    # print()

    start = perf_counter_ns()
    var expected = simple_negamax(game, 0, max_depth)
    print("==== expected:", expected, "time:", Float64(perf_counter_ns() - start) / 1_000_000_000)

    var best_move = root.children[0].copy()
    print("### complete", complete)
    for ref child in root.children:
        print("### move", child)

        if child.score > best_move.score:
            best_move = child.copy()
    print("### best move", best_move)
    print()
