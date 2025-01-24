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
        for i in 1:10_000
            cont = expand!(tree, game)
            if game.stone == black && tree.root.decision == black_win
                println("decision: Black win after $i expands")
                break
            elseif game.stone == white && tree.root.decision == white_win
                println("decision: White win after $i expands")
                break
            end
            if !cont
                println("decision: single undecided after $i expands")
                break
            end
        end
        move = best_move(tree, game)
        println("move: $move, turn: $(game.stone) dec: $(tree.root.decision)")
        commit_move!(tree, game, "$move")
        println(game.stones)
        term = isterminal(game)
        if !isnothing(term)
            println(term)
            break
        end
    end
end

# run_simulation(gomoku)
run_simulation(connect6)
