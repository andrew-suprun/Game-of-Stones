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
        writer.write("<", self._id, ">")


alias zero_move = MoveScore(TestMove(), Score(0))

# struct TestGame(TGame):
struct TestGame(Writable):
    alias Move = TestMove

    var _moves: Dict[Int, MoveScore[TestMove]]
    var _current_id: Int

    fn __init__(out self):
        self = Self(5, 0)

    fn __init__(out self, depth: Int, seed: Int):
        random.seed(seed)
        self._current_id = 0
        self._moves = Dict[Int, MoveScore[TestMove]]()
        self._moves[0] = MoveScore(TestMove(0), Score())
        self._init_moves(0, depth)

    fn _init_moves(mut self, var id: Int, depth: Int):
        id *= 10
        var n_children = Int(random.random_si64(1, 5))
        for _ in range(n_children):
            id += 1
            var rand = random.random_si64(0, 12)
            if rand == 0:
                self._moves[id] = MoveScore(TestMove(id), Score.win())
            elif rand == 1 or depth == 0:
                self._moves[id] = MoveScore(TestMove(id), Score.draw())
            else:
                self._moves[id] = MoveScore(TestMove(id), Score(random.random_float64(-10, 10)))
                self._init_moves(id, depth-1)

    fn _current_move(self) -> MoveScore[TestMove]:
        return self._moves.get(self._current_id, zero_move)

    fn score(self) -> Score:
        return self._current_move().score

    fn move(self) -> MoveScore[TestMove]:
        var move = self._current_move()
        var child_id = move.move._id
        return self._moves.get(child_id, zero_move)

    fn moves(self) -> List[MoveScore[TestMove]]:
        var moves = List[MoveScore[TestMove]]()
        var id = self._current_id*10
        try:
            while True:
                id += 1
                moves.append(self._moves[id])
        except:
            pass
        return moves

    fn play_move(mut self, move: self.Move) -> Score:
        return 0

    fn hash(self) -> Int:
        return 0

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass
