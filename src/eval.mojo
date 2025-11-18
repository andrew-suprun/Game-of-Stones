from time import perf_counter_ns

from traits import TTree

fn run[Tree: TTree](opening: String) raises:
    var game = Tree.Game()
    var tree = Tree()
    var open_moves = opening.split(" ")
    for move_str in open_moves:
        _ = game.play_move(Tree.Game.Move(String(move_str)))
    print("opening", opening)
    print(game)

    var start = perf_counter_ns()
    var move = tree.search(game, 60_000)
    print("search result", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
