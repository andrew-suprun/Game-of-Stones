from time import perf_counter_ns

from traits import TTree


fn run[Tree: TTree](opening: String) raises:
    var game = Tree.Game()
    var state = Tree.Game.State()
    var tree = Tree()
    var open_moves = opening.split(" ")
    print("opening", opening)
    for move_str in open_moves:
        state = game.play_move(state, Tree.Game.State.Move(String(move_str)))
    print(state)

    var start = perf_counter_ns()
    var move = tree.search(game, state, 1000)
    print("search result", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
