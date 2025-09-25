from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore

alias debug = env_get_int["DEBUG2", 0]()


struct NegamaxZero[G: TGame](TTree):
    alias Game = G

    var roots: List[Node[G]]

    fn __init__(out self):
        self.roots = List[Node[G]]()

    fn search(mut self, mut game: G, duration_ms: Int) -> MoveScore[G.Move]:
        @parameter
        fn greater(a: MoveScore[G.Move], b: MoveScore[G.Move]) -> Bool:
            return a.score > b.score

        self.roots = List[Node[G]]()
        var deadline = perf_counter_ns() + 1_000_000 * duration_ms
        var moves = game.moves()
        debug_assert(len(moves) > 0)
        # sort[greater](moves)

        if len(moves) == 1:
            return moves[0]

        self.roots.reserve(len(moves))
        for move in moves:
            self.roots.append(Node(move, 0, Bounds()))

        var max_depth = 9
        # var guess = Score(0)
        var guess = Score.loss()
        var node = Pointer(to=self.roots[0])
        var start = perf_counter_ns()
        while True:
            if debug > 0:
                print("----")
                print(">>", node[], "guess", guess)
            _ = game.play_move(node[].move)  # TODO handle decisive move
            node[].negamax_zero(game, guess, max_depth, deadline)
            game.undo_move(node[].move)

            if deadline < perf_counter_ns():
                if debug > 0:
                    print("@@@ deadline")
                break


            if debug > 0:
                for ref root in self.roots:
                    print(root)
                print("<<", node[], "guess", guess)

            guess = Score.loss()
            for ref node in self.roots:
                guess = max(guess, node.bounds.lower)

            var node_set = False
            var top_selections = 0
            for ref root in self.roots:
                if root.bounds.lower == guess:
                    top_selections += 1
                    continue

                if root.bounds.upper <= guess:
                    continue

                if not node_set or root.bounds.lower < node[].bounds.lower:
                    node = Pointer(to=root)
                    node_set = True

            if node_set:
                # if debug > 0:
                #     print("node set")
                continue

            # if debug > 0:
            #     print("top_selections", top_selections)

            node_set = False
            if top_selections == 1:
                for ref root in self.roots:
                    if root.bounds.lower == guess:
                        node = Pointer(to=root)
                        node_set = True
                        break

            if node_set:
                break

            for ref root in self.roots:
                if root.bounds.lower == guess:
                    if not node_set:
                        node_set = True
                        node = Pointer(to=root)
                    else:
                        if node[].bounds.upper < root.bounds.upper:
                            node = Pointer(to=root)

            if node[].bounds.lower == node[].bounds.upper:
                break

        node = Pointer(to=self.roots[0])
        for ref root in self.roots:
            if root.bounds.lower == guess:
                node = Pointer(to=root)
                break

        print("result", node[], "time", Float64(perf_counter_ns() - start) / 1_000_000)
        return MoveScore[G.Move](node[].move, node[].bounds.lower)


@fieldwise_init
struct Bounds(Defaultable, ImplicitlyCopyable, Movable, Stringable, Writable):
    var lower: Score
    var upper: Score

    fn __init__(out self):
        self.lower = Score.loss()
        self.upper = Score.win()

    fn is_decisive(self) -> Bool:
        return self.lower.is_decisive() and self.lower == self.upper

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self.lower == self.upper:
            writer.write("score: ", self.lower)
        else:
            writer.write("bounds: (", self.lower, " : ", self.upper, ")")


struct Node[G: TGame](Copyable, Movable, Stringable, Writable):
    var move: G.Move
    var bounds: Bounds
    var max_depth: Int
    var children: List[Self]

    fn __init__(out self, move: MoveScore[G.Move], depth: Int, bounds: Bounds):
        self.move = move.move
        self.bounds = bounds
        self.max_depth = depth
        self.children = List[Self]()

    fn __init__(out self, move: MoveScore[G.Move], depth: Int):
        self = self.__init__(move, depth, Bounds(move.score, move.score))

    fn __copyinit__(out self, existing: Self, /):
        self.move = existing.move
        self.bounds = existing.bounds
        self.max_depth = existing.max_depth
        self.children = List[Self]()

    fn negamax_zero(mut self, mut game: G, guess: Score, max_depth: Int, deadline: UInt):
        self.negamax_zero(game, guess, 0, max_depth, deadline)

    fn negamax_zero(mut self, mut game: G, guess: Score, depth: Int, max_depth: Int, deadline: UInt):
        @parameter
        fn greater(a: Self, b: Self) -> Bool:
            if a.bounds.lower > b.bounds.lower:
                return True
            if a.bounds.lower < b.bounds.lower:
                return False
            return a.bounds.upper > b.bounds.upper

        if deadline < perf_counter_ns():
            return

        if depth < max_depth and not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0)
            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Self(move, depth + 1))

        if depth + 1 == max_depth:
            self.max_depth = max_depth
            self.bounds = Bounds()
            for ref child in self.children:
                self.bounds.upper = min(self.bounds.upper, -child.bounds.lower)
                child.max_depth = max_depth
                if debug > 1:
                    print("|   " * depth + "== leaf", child)
            self.bounds.lower = self.bounds.upper
            return

        sort[greater](self.children)

        for ref child in self.children:
            if debug > 1:
                print("|   " * depth + ">", depth, child)

            if child.max_depth == max_depth and child.bounds.lower == child.bounds.upper:
                self.bounds.upper = min(self.bounds.upper, -child.bounds.lower)
                if debug > 1:
                    print("|   " * depth + "< skip")
                continue
            if child.bounds.lower < child.bounds.upper or not child.bounds.lower.is_decisive():
                child.bounds = Bounds()
                _ = game.play_move(child.move)
                child.negamax_zero(game, -guess, depth + 1, max_depth, deadline)
                game.undo_move(child.move)

            child.max_depth = max_depth
            self.bounds.upper = min(self.bounds.upper, -child.bounds.lower)

            if self.bounds.upper < guess:
                if debug > 1:
                    print("|   " * depth + "<", depth, "cut-off", child)
                return
            elif debug > 1:
                print("|   " * depth + "<", depth, child)

        self.bounds.lower = Score.win()
        for child in self.children:
            self.bounds.lower = min(self.bounds.lower, -child.bounds.upper)

        return

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("move: ", self.move, "; ", self.bounds, "; depth: ", self.max_depth)

    fn print_tree(self):
        self.print_tree(0)

    fn print_tree(self, depth: Int):
        print("|   " * depth + String(self))
        if self.children:  # this is to prevent Mojo warning
            for child in self.children:
                child.print_tree(depth + 1)


from connect6 import Connect6
from negamax import Negamax


fn main() raises:
    alias Game = Connect6[size=19, max_moves=8, max_places=6, max_plies=100]
    var game = Game()
    var tree1 = NegamaxZero[Game]()
    # var tree2 = Negamax[Game]()
    _ = game.play_move("j10")
    _ = game.play_move("i9-i10")
    while True:
        var move1 = tree1.search(game, 20_000)
        print("zero", move1)
        # print("----")
        # var move2 = tree2.search(game, 20_000)
        # print("nmax", move2)

        # var result = game.play_move(move2.move)
        # print(game)

        # if result.is_decisive():
        #     break
        break
