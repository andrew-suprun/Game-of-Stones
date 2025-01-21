include("interface.jl")
include("game.jl")
include("game_values.jl")

using BenchmarkTools

game = Game(Val(:Connect6), 20)

function bench_place_stone()
    place_stone!(game, Val(:Connect6), Place(10, 10), 1)
    place_stone!(game, Val(:Connect6), Place(10, 10), -1)
end

function bench_play_move()
    play_move!(game, Val(:Connect6), Move(Place(9, 9), Place(10, 10)))
    undo_move!(game, Val(:Connect6), Move(Place(9, 9), Place(10, 10)))
end


