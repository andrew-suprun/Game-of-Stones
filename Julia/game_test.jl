using Test

include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_show.jl")

# @show game_values(Val(:Gomoku), Val(:First), 1 + 2)
# @show game_values(Val(:Gomoku), Val(:Second), 1 + 2 * 6)
# @show game_values(Val(:Connect6), Val(:First), 1 + 3)
# @show game_values(Val(:Connect6), Val(:Second), 1 + 3 * 6)


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

function bench_init()
    for _ in 1:1_000_000
        init_values(Val(:Connect6))
    end
end

function test_board_values()
    game = Game(Val(:Connect6))
    v = board_values(game, Val(:Connect6))
    for y in 1:size
        for x in 1:size
            game.stones[x, y] = 1
            if v[x, y, 1] != board_value(game, Val(:Connect6))
                return false
            end
            game.stones[x, y] = 6
            if v[x, y, 2] != board_value(game, Val(:Connect6))
                return false
            end
            game.stones[x, y] = 0
        end
    end
    return true
end

@test test_board_values()

