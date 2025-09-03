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


struct TestNode(Copyable, Movable):
    var move: MoveScore[TestMove]
    var children: List[Self]

    fn __init__(out self, move: MoveScore[TestMove], depth: Int):
        id = 10*move.move._id+1
        var n_children = Int(random.random_si64(1, 5))
        self.children = List[Self](capacity=n_children)
        for _ in range(n_children):
            var rand = random.random_si64(0, 12)
            if rand == 0:
                self.children.append(Self(MoveScore(TestMove(id), Score.win()), 0))
            elif rand == 1 or depth == 0:
                self.children.append(Self(MoveScore(TestMove(id), Score.draw()), 0))
            else:
                var child = Self(MoveScore(TestMove(id), Score(random.random_float64(-10, 10))), depth-1)
                self.children.append(child^)
            id += 1

# struct TestGame(TGame):
struct TestGame:
    alias Move = TestMove

    var root: TestNode

    fn __init__(out self):
        random.seed(0)
        self.root = TestNode(MoveScore(TestMove(), Score()), 0)

    fn __init__(out self, depth: Int, seed: Int):
        random.seed(seed)
        self.root = TestNode(MoveScore(TestMove(), Score()), depth)

    fn __copyinit__(out self, other: Self, /):
        self.move_id = other.move_id

    fn copy(self) -> Self:
        return self

    fn score(self) -> Score:
        return Score(random_float64(-10, 10))

    fn move(self) -> MoveScore[TestMove]:
        return MoveScore(TestMove(0), Score(random_float64(-10, 10)))

    fn moves(self) -> List[MoveScore[TestMove]]:
        var moves = List[MoveScore[TestMove]]()
        var n_moves = random_si64(2, 5)
        var id = self.move_id
        for _ in range(n_moves):
            var rand = random_si64(0, 12)
            if rand == 0:
                moves.append(MoveScore(TestMove(id), Score.win()))
            elif rand == 1:
                moves.append(MoveScore(TestMove(id), Score.draw()))
            else:
                moves.append(MoveScore(TestMove(id), Score(random_float64(-10, 10))))
            id += 1
        return moves

    fn play_move(mut self, move: self.Move) -> Score:
        return 0

    fn hash(self) -> Int:
        return 0

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass
