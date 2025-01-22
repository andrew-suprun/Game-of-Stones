include("interface.jl")
include("game.jl")
include("game_values.jl")

using BenchmarkTools

game = Game(connect6)

function bench_place_stone()
    place_stone!(game, Place(10, 10), 1)
    place_stone!(game, Place(10, 10), -1)
end

function bench_play_move()
    play_move!(game, Move(Place(9, 9), Place(10, 10)))
    undo_move!(game, Move(Place(9, 9), Place(10, 10)))
end


