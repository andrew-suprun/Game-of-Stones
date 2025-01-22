include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")

function run_simulation(name)
    println("\n--- $name")
    game = Game(name)
    play_move!(game, name, Move(Place(10, 10), Place(10, 10)))
    if name == Val(:Gomoku)
        play_move!(game, name, Move(Place(9, 9), Place(9, 9)))
    else
        play_move!(game, name, Move(Place(9, 9), Place(9, 10)))
    end
    println(game.stones)
    moves = Vector{MoveValue}()
    while true
        top_moves(game, name, moves)
        move = moves[1]
        for m in moves
            if move.value < m.value && game.stone == Black || move.value > m.value && game.stone == White
                move = m
            end
        end
        @show move
        play_move!(game, name, move.move)
        println(game.stones)
        if move.isterminal
            break
        end
    end
end

run_simulation(Val(:Gomoku))
run_simulation(Val(:Connect6))