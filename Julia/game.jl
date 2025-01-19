struct Place
    x::Int8
    y::Int8
end

struct Move
    p1::Place
    p2::Place
end

Move() = Move(Place(0, 0), Place(0, 0))

const None = 0
const Black = 1
const White = 6

mutable struct Game
    stones::Matrix{Int8}
    values::Array{Int16,3}
    value::Int16
    stone::Int8

    function Game(name)
        stones = zeros(Int8, size, size)
        values = init_values(name)
        return new(stones, values, 0, Black)
    end
end

function init_values(name)
    ms = max_stones(name)
    values = Array{Int16,3}(undef, 2, size, size)
    for y in 1:size
        v = min(ms, y, size + 1 - y)
        for x in 1:size
            h = min(ms, x, size + 1 - x)
            m = min(x, y, size + 1 - x, size + 1 - y)
            t1 = max(0, min(ms, m, size + 1 - ms - y + x, size + 1 - ms - x + y))
            t2 = max(0, min(ms, m, 2 * size - ms - y - x, x + y - ms))
            total = v + h + t1 + t2
            values[1, x, y] = total
            values[2, x, y] = -total
        end
    end
    values
end

max_stones(::Val{:Gomoku}) = 5
max_stones(::Val{:Connect6}) = 6

function play_move!(game::Game, name, move::Move)
    place_stone!(game, name, move.p1, 1)

    if move.p1 != move.p2
        place_stone!(game, name, move.p2, 1)
    end

    next_turn!(game)

    validate(game, debug)
end

function undo_move!(game::Game, move::Move)
    next_turn!(game)

    if move.p1 != move.p2
        place_stone!(game, name, move.p2, -1)
    end

    place_stone!(game, name, move.p1, -1)

    validate(game, debug)
end

next_turn!(game::Game) = game.stone = 7 - game.stone

function place_stone!(game::Game, name, place::Place, coeff)
    turn_idx = game.stone == Black ? 1 : 2
    x, y = place.x, place.y
    if coeff == 1
        game.value += game.values[turn_idx, x, y]
    else
        game.stones[x, y] = None
    end

    ms = max_stones(name)
    begin
        start_x = max(1, x - ms)
        end_x = min(x + ms, size) - ms
        n = end_x - start_x
        update_row!(game, name, start_x, y, 1, 0, n, coeff)
    end

    begin
        start_y = max(1, y - ms)
        end_y = min(y + ms, size) - ms
        n = end_y - start_y
        update_row!(game, name, x, start_y, 0, 1, n, coeff)
    end

    m = 1 + min(x, y, size - x, size - y)

    begin
        n = min(ms, m, size - ms - y + x, size - ms - x + y)
        if n > 0
            mn = min(x, y, ms)
            xStart = x - mn + 1
            yStart = y - mn + 1
            update_row!(game, name, xStart, yStart, 1, 1, n, coeff)
        end
    end

    begin
        n = min(ms, m, 2 * size - ms - y - x, x + y - ms)
        if n > 0
            mn = min(size - x, y, ms)
            xStart = x + mn
            yStart = y - mn
            update_row!(game, name, xStart, yStart, -1, 1, n, coeff)
        end
    end

    if coeff == 1
        game.stones[x, y] = game.stone
    else
        game.value -= game.values[turn_idx, x, y]
    end
    validate(game, debug)
end

function update_row!(game::Game, name, x, y, dx, dy, n, coeff::Int16)
    stones = 1
    for i in 1:max_stones(name)
        stones += game.stones[x+i*dx, y+i*dy]
    end
    ms1 = max_stones(name) - 1
    for _ in 1:n
        stones += game.stones[x+ms1*dx, y+ms1*dy]
        b_value, w_value = game_values(name, game.stone, stones)
        if b_value != 0 || w_value != 0
            b_value, w_value = b_value * coeff, w_value * coeff
            for j in 0:ms1 # TODO manually unroll?
                game.values[1, x+j*dx, y+j*dy] += b_value
                game.values[2, x+j*dx, y+j*dy] += w_value
            end
        end
        stones -= game.stones[x, y]
        x += dx
        y += dy
    end
end

function board_value(game::Game, name)::Int16
    result = Int16(0)
    ms = max_stones(name)
    for y in 1:size
        stones = 1
        for x in 1:ms-1
            stones += game.stones[x, y]
        end
        for x in 1:size-ms+1
            stones += game.stones[x+ms-1, y]
            result += stones_value(name, stones)
            stones -= game.stones[x, y]
        end
    end
    for x in 1:size
        stones = 1
        for y in 1:ms-1
            stones += game.stones[x, y]
        end
        for y in 1:size-ms+1
            stones += game.stones[x, y+ms-1]
            result += stones_value(name, stones)
            stones -= game.stones[x, y]
        end
    end
    for y in 1:size+1-ms
        stones = 1
        for x in 1:ms-1
            stones += game.stones[x, y+x-1]
        end
        for x in 1:size+2-ms-y
            stones += game.stones[x+ms-1, x+y+ms-2]
            result += stones_value(name, stones)
            stones -= game.stones[x, x+y-1]
        end
    end
    for x in 2:size+1-ms
        stones = 1
        for y in 1:ms-1
            stones += game.stones[x+y-1, y]
        end
        for y in 1:size+2-ms-x
            stones += game.stones[x+y+ms-2, y+ms-1]
            result += stones_value(name, stones)
            stones -= game.stones[x+y-1, y]
        end
    end
    for y in 1:size+1-ms
        stones = 1
        for x in 1:ms-1
            stones += game.stones[size+1-x, y+x-1]
        end
        for x in 1:size+2-ms-y
            stones += game.stones[size+2-x-ms, x+y+ms-2]
            result += stones_value(name, stones)
            stones -= game.stones[size+1-x, x+y-1]
        end
    end
    for x in 2:size+1-ms
        stones = 1
        for y in 1:ms-1
            stones += game.stones[size+2-x-y, y]
        end
        for y in 1:size+2-ms-x
            stones += game.stones[size+3-x-y-ms, y+ms-1]
            result += stones_value(name, stones)
            stones -= game.stones[size+2-x-y, y]
        end
    end

    result
end

# TODO: Use Unroll.jl?
# TODO: Use @inbounds?
function board_values(game::Game, name)::Array{Int16,3}
    result = zeros(Int16, 2, size, size)
    ms = max_stones(name)
    for y in 1:size
        stones = 1
        for x in 1:ms-1
            stones += game.stones[x, y]
        end
        for x in 1:size-ms+1
            stones += game.stones[x+ms-1, y]
            for i in 0:ms-1
                b_value, w_value = stones_values(name, stones)
                result[1, x+i, y] += b_value
                result[2, x+i, y] += w_value
            end
            stones -= game.stones[x, y]
        end
    end
    for x in 1:size
        stones = 1
        for y in 1:ms-1
            stones += game.stones[x, y]
        end
        for y in 1:size-ms+1
            stones += game.stones[x, y+ms-1]
            for i in 0:ms-1
                b_value, w_value = stones_values(name, stones)
                result[1, x, y+i] += b_value
                result[2, x, y+i] += w_value
            end
            stones -= game.stones[x, y]
        end
    end
    for y in 1:size+1-ms
        stones = 1
        for x in 1:ms-1
            stones += game.stones[x, y+x-1]
        end
        for x in 1:size+2-ms-y
            stones += game.stones[x+ms-1, x+y+ms-2]
            for i in 0:ms-1
                b_value, w_value = stones_values(name, stones)
                result[1, x+i, x+y+i-1] += b_value
                result[2, x+i, x+y+i-1] += w_value
            end
            stones -= game.stones[x, x+y-1]
        end
    end
    for x in 2:size+1-ms
        stones = 1
        for y in 1:ms-1
            stones += game.stones[x+y-1, y]
        end
        for y in 1:size+2-ms-x
            stones += game.stones[x+y+ms-2, y+ms-1]
            for i in 0:ms-1
                b_value, w_value = stones_values(name, stones)
                result[1, x+y+i-1, y+i] += b_value
                result[2, x+y+i-1, y+i] += w_value
            end
            stones -= game.stones[x+y-1, y]
        end
    end
    for y in 1:size+1-ms
        stones = 1
        for x in 1:ms-1
            stones += game.stones[size+1-x, y+x-1]
        end
        for x in 1:size+2-ms-y
            stones += game.stones[size+2-x-ms, x+y+ms-2]
            for i in 0:ms-1
                b_value, w_value = stones_values(name, stones)
                result[1, size-x-i+1, x+y+i-1] += b_value
                result[2, size-x-i+1, x+y+i-1] += w_value
            end
            stones -= game.stones[size+1-x, x+y-1]
        end
    end
    for x in 2:size+1-ms
        stones = 1
        for y in 1:ms-1
            stones += game.stones[size+2-x-y, y]
        end
        for y in 1:size+2-ms-x
            stones += game.stones[size+3-x-y-ms, y+ms-1]
            for i in 0:ms-1
                b_value, w_value = stones_values(name, stones)
                result[1, size+2-x-y-i, y+i] += b_value
                result[2, size+2-x-y-i, y+i] += w_value
            end
            stones -= game.stones[size+2-x-y, y]
        end
    end
    result
end

function top_moves(game::Game, moves::Vector{MoveValue{Move}}, max_moves::Int)
    error("TODO: Implement")
end

function parse_move(move::String)::Move
    tokens = split(move, '-')
    p1 = parse_place(tokens[begin])

    if length(tokens) == 1
        return Move(p1, p1)
    end
    p2 = parse_place(tokens[end])
    Move(p1, p2)
end

function parse_place(place)::Place
    if length(place) < 2 || length(place) > 3
        throw(ArgumentError("Invalid Place"))
    end
    if place[1] < 'a' || place[1] > 's'
        throw(ArgumentError("Invalid Place"))
    end
    if place[2] < '0' || place[2] > '9'
        throw(ArgumentError("Invalid Place"))
    end
    x = place[1] + 1 - 'a'
    y = place[2] - '0'
    if length(place) == 3
        if place[3] < '0' || place[3] > '9'
            throw(ArgumentError("Invalid Place"))
        end
        y = 10 * y + place[3] - '0'
    end
    y = size + 1 - y
    if x > size || y > size
        throw(ArgumentError("Invalid Place"))
    end
    Place(x, y)
end

game_values(::Val{:Gomoku}, stone, stones) =
    stone == Black ? gomoku_first[stones] : gomoku_second[stones]

game_values(::Val{:Connect6}, stone, stones) =
    stone == Black ? connect6_first[stones] : connect6_second[stones]

stones_values(::Val{:Connect6}, stones) = connect6_values[stones]
stones_values(::Val{:Gomoku}, stones) = gomoku_values[stones]

stones_value(::Val{:Connect6}, stones) = connect6_value[stones]
stones_value(::Val{:Gomoku}, stones) = gomoku_value[stones]

function validate(game::Game, debug::Val{true})
    # TODO: Implement
    # error("TODO: Implement")
end

validate(game::Game, debug::Val{false}) = nothing
