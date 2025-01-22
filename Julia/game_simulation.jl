include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")

function run_simulation(name)
    game = Game(name)
    play_move!(game, name, Move(Place(10, 10), Place(10, 10)))
    moves = Vector{MoveValue}()
    top_moves(game, name, moves)
    println(game.stones)
    for move in moves
        println(move)
    end
end

run_simulation(Val(:Gomoku))
# run_simulation(Val(:Connect6))