include("interface.jl")
include("game.jl")
include("game_values.jl")
include("tree.jl")

using BenchmarkTools


gomoku_game = Game(gomoku)
gomoku_tree = Tree{Move}(20.0)
function bench_expand_gomoku()
    expand!(gomoku_tree, gomoku_game)
end

connect6_game = Game(gomoku)
connect6_tree = Tree{Move}(20.0)
function bench_expand_connect6()
    expand!(connect6_tree, connect6_game)
end

