from std.time import perf_counter_ns

from engine import Gomoku, Connect6b, Mcts, Score, Board
from engine import AlphaBetaNegamax, PrincipalVariationNegamax

comptime Game = Connect6b[size=19, max_moves=26, max_places=26]
# comptime Game = Gomoku[size=19, max_moves=26]

comptime Tree = Mcts[Game, Score(0.4)]
# comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]

comptime script = (
    "j10 i10-j11 k12-l12 s:52.0 i12-i9 i11-l9 s:54.0 k8-l8 k11-n14 s:148.0 k13-m13 l13-l14 s:185.0 m14-l11 m12-n12 s:285.0 n11-o12 l15-m9 s:120.0 l16-n8 m7-m8 s:168.0 p13-m10"
    " n7-r15 s:68.0 p11-o11 m6-q11 s:186.0 m5-n13 o13-q10 s:186.0 p9-p12 p8-p14 s:181.0 k7-l6 j8-q15 s:499.0 l10-r16 o6-q7 s:413.0 p5-q9 n10-o9 s:935.0 r6-m11 o7-q13 s:456.0"
    " q12-p7 n16-o15 s:452.0 l18-r12 m15-n15 s:1672.0 k15-p15 n18-o17 s:277.0 p18-n17 o14-r14 s:455.0 q14-o16"
)


comptime win_stones = 6
comptime values: List[Float32] = [0, 1, 100, 1000, 10_000, 100_000]


def main() raises:
    var values = Board[19, values, win_stones].value_table
    print(values)
    for turn in range(2):
        for color in range(2):
            for y in range(6):
                for x in range(6):
                    print(String(values[color][y * 6 + x][turn]).ascii_rjust(8), " ", end="")
                print()
            print()

    var game = Tree.Game()
    var tree = Tree()
    var open_moves = script.split(" ")
    print("opening", script)
    for move in open_moves:
        var move_str = String(move)
        if move_str.startswith("s:"):
            continue
        game.play_move({move_str})
        print(t"move: {move_str}")
        var start = perf_counter_ns()
        var pv = tree.search(game, 100)
        print(repr(game))
        print("search result", pv, "time.ms", Float64(perf_counter_ns() - start) / 1_000_000)
        print(tree)
