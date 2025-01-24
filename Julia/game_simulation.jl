#!/usr/bin/env julia

include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")
include("tree.jl")

function run_simulation(name)
    println("\n--- $name")
    tree = Tree{Move}(20.0)
    game = Game(name)
    play_move!(game, Move(Place(10, 10)))
    if name == gomoku
        play_move!(game, Move(Place(9, 9)))
    else
        play_move!(game, Move(Place(9, 9), Place(9, 10)))
    end
    println(game.stones)
    while true
        for _ in 1:10_000
            expand!(tree, game)
            if tree.root.decision != no_decision
                println("decision: $(tree.root.decision)")
                break
            end
        end
        move = best_move(tree)
        println(move)
        commit_move!(tree, game, "$move")
        println(game.stones)
        tree.root.terminal != no_decision && break
    end
end

run_simulation(gomoku)
# run_simulation(connect6)

# tree = Tree{Move}(20.0)
# game = Game(gomoku)
# play_move!(game, Move(Place(10, 10)))
# play_move!(game, Move(Place(9, 9)))
# println(game.values)
# for _ in 1:20_000
#     expand!(tree, game)
# end