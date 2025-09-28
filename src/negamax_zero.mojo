from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore

alias debug = env_get_int["DEBUG2", 0]()


fn search[Game: TGame](mut game: Game, duration_ms: Int) -> MoveScore[Game.Move]:
    var root = Node[Game](MoveScore[Game.Move](Game.Move(), Score()))
    var deadline = perf_counter_ns() + 1_000_000 * duration_ms

    var max_depth = 0
    var start = perf_counter_ns()
    var best_move = Game.Move()
    var best_score = Score.loss()
    while True:
        max_depth += 1
        _ = root.search(game, Score.loss(), Score.win(), max_depth, deadline)

        if debug > 0:
            print("---- max-depth", max_depth)
            for ref child in root.children:
                print(">>", child)

        if deadline < perf_counter_ns():
            if debug > 0:
                print("@@@ deadline")
            break

        best_move = Game.Move()
        best_score = Score.loss()
        for ref child in root.children:
            if debug > 0:
                print("### move", child)
            if best_score < child.score:
                best_move = child.move
                best_score = child.score

        if debug > 0:
            print("### best move", best_move, best_score)

    print("result", best_move, "time", Float64(perf_counter_ns() - start) / 1_000_000)
    return MoveScore[Game.Move](best_move, best_score)


struct Node[Game: TGame](Copyable, Movable, Stringable, Writable):
    var move: Game.Move
    var score: Score
    var children: List[Self]

    fn __init__(out self, move: MoveScore[Game.Move]):
        self.move = move.move
        self.score = move.score
        self.children = List[Self]()

    fn __copyinit__(out self, existing: Self, /):
        self.move = existing.move
        self.score = existing.score
        self.children = List[Self]()

    fn search(mut self, mut game: Game, lower: Score, var upper: Score, max_depth: Int, deadline: UInt):
        _ = self.search(game, lower, upper, 0, max_depth, deadline)

    fn search(mut self, mut game: Game, lower: Score, var upper: Score, depth: Int, max_depth: Int, deadline: UInt, out complete: Bool):
        @parameter
        fn greater(a: Self, b: Self) -> Bool:
            return a.score > b.score

        if debug > 0:
            print("|   " * depth + ">> search: (", lower, ":", upper, ") ", depth, "/", max_depth, sep="")

        if deadline < perf_counter_ns():
            if debug > 0:
                print("|   " * depth + "<< deadline")
            return False

        if depth <= max_depth and not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0)
            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Self(move))

        self.score = Score.win()
        if depth == max_depth:
            for ref child in self.children:
                self.score = min(self.score, -child.score)
                if debug > 1:
                    print("|   " * depth + "== leaf", child)
            if debug > 0:
                print("|   " * depth + "<< search-1", self)
            return True

        sort[greater](self.children)

        ref child = self.children[0]

        if debug > 1:
            print("|   " * depth + ">", depth, "first", child, "self", self, "|", lower, upper)

        if child.score.is_win():
            self.score = Score.loss()
            if debug > 1:
                print("|   " * depth + "<", depth, "first losing", child.move, "self", self, "|", lower, upper)
            return True

        _ = game.play_move(child.move)
        _ = child.search(game, -upper, -lower, depth + 1, max_depth, deadline)
        game.undo_move(child.move)
        self.score = -child.score
        upper = min(upper, self.score)
        if debug > 1:
            print("|   " * depth + "<", depth, "first", child, "self", self, "|", lower, upper)

        for idx in range(1, len(self.children)):
            ref child = self.children[idx]
            if debug > 1:
                print("|   " * depth + ">", depth, child, "|", lower, upper)

            if not child.score.is_decisive():
                _ = game.play_move(child.move)
                var complete = child.search(game, -upper, -upper, depth + 1, max_depth, deadline)
                self.score = min(self.score, -child.score)
                upper = min(upper, self.score)
                if debug > 1:
                    print("|   " * depth + "=", depth, "zero", child, "self", self, "|", lower, upper)

                if self.score > upper:
                    game.undo_move(child.move)
                    if debug > 1:
                        print("|   " * depth + "<", depth, "cut-off", child)
                    return False

                if complete:
                    game.undo_move(child.move)

                    if debug > 1:
                        print("|   " * depth + "<", depth, "next-1", child, "|", lower, upper)
                    continue

                else:
                    _ = child.search(game, -upper, -lower, depth + 1, max_depth, deadline)
                    self.score = min(self.score, -child.score)
                    upper = min(upper, self.score)

                game.undo_move(child.move)

                if debug > 1:
                    print("|   " * depth + "<", depth, "next-2", child, "|", lower, upper)

        if debug > 0:
            print("|   " * depth + "<< search-2", self)

        return True

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " ", self.score)

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
    # var tree2 = Negamax[Game]()
    _ = game.play_move("j10")
    _ = game.play_move("i9-i10")
    while True:
        var move1 = search(game, 1000)
        print("zero", move1)
        # print("----")
        # var move2 = tree2.search(game, 20_000)
        # print("nmax", move2)

        # var result = game.play_move(move2.move)
        # print(game)

        # if result.is_decisive():
        #     break
        break
