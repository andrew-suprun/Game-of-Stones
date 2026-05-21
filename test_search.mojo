from std.testing import assert_true
from std.time import perf_counter_ns

from game_of_stones import TTree, Mcts, AlphaBetaNegamax, PrincipalVariationNegamax, Gomoku, Connect6


def test_search[Tree: TTree, moves: List[String], expected: String]() raises:
    print(t"testing: tree {reflect[Tree].base_name()} game {reflect[Tree.Game].base_name()}")
    var tree = Tree()
    var game = Tree.Game()
    comptime for move in moves:
        game.play_move(Tree.Game.Move(move))
    print(game)
    var result = tree.search(game, 16, 1000)
    print(
        t"result: {result[0]}  expected: {expected}  pv: {len(result)} {result}",
    )
    assert_true(String(result[0]) == expected)


def main() raises:
    comptime GomokeGame = Gomoku[size=19, max_plies=100]
    comptime Connect6Game = Connect6[size=19, max_plies=100]
    test_search[Mcts[GomokeGame, 16], ["j10", "i9", "i10"], "h10"]()
    test_search[Mcts[Connect6Game, 16], ["j10", "i9-i10"], "i11-k9"]()
    test_search[AlphaBetaNegamax[GomokeGame], ["j10", "i9", "i10"], "h10"]()
    test_search[AlphaBetaNegamax[Connect6Game], ["j10", "i9-i10"], "i11-k9"]()
    test_search[PrincipalVariationNegamax[GomokeGame], ["j10", "i9", "i10"], "h10"]()
    test_search[PrincipalVariationNegamax[Connect6Game], ["j10", "i9-i10"], "i11-k9"]()
