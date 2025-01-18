include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_show.jl")

# @show game_values(Val(:Gomoku), Val(:First), 1 + 2)
# @show game_values(Val(:Gomoku), Val(:Second), 1 + 2 * 6)
# @show game_values(Val(:Connect6), Val(:First), 1 + 3)
# @show game_values(Val(:Connect6), Val(:Second), 1 + 3 * 6)

game = Game(Val(:Gomoku))

function bench(game)
    v = 0
    for _ in 1:10_000
        for y in 1:size
            for x in 1:size
                game.stones[x, y] = 1
                v += board_value(game, Val(:Connect6))
                game.stones[x, y] = 0
            end
        end
    end
    v
end

@time bench(game)
