include("heap.jl")

const n_places::Int = 20
const n_moves::Int = 64

struct Place
    x::Int8
    y::Int8
end

struct Move
    p1::Place
    p2::Place
end

Move() = Move(Place(0, 0), Place(0, 0))

const None::Int8 = 0
const Black::Int8 = 1
const White::Int8 = 8

mutable struct Game
    name::Union{Name{:Gomoku},Name{:Connect6}}
    stones::Matrix{Int8}
    values::Array{Int16,3}
    places::Vector{Place}
    value::Int16
    stone::Int8
    turn_idx::Int8

    function Game(name)
        stones = zeros(Int8, board_size, board_size)
        values = init_values(name)
        new(name, stones, values, Vector{Place}(), 0, Black, 1)
    end
end

function init_values(name)
    ms = max_stones(name)
    values = Array{Int16,3}(undef, 2, board_size, board_size)
    for y in 1:board_size
        v = min(ms, y, board_size + 1 - y)
        for x in 1:board_size
            h = min(ms, x, board_size + 1 - x)
            m = min(x, y, board_size + 1 - x, board_size + 1 - y)
            t1 = max(0, min(ms, m, board_size + 1 - ms - y + x, board_size + 1 - ms - x + y))
            t2 = max(0, min(ms, m, 2board_size + 2 - ms - y - x, x + y - ms))
            total = v + h + t1 + t2
            values[1, x, y] = total
            values[2, x, y] = -total
        end
    end
    values
end

max_stones(::Name{:Gomoku}) = 5
max_stones(::Name{:Connect6}) = 6

function play_move!(game, move)
    place_stone!(game, move.p1, 1)

    if move.p1 != move.p2
        place_stone!(game, move.p2, 1)
    end

    next_turn!(game)
end

function undo_move!(game, move)
    next_turn!(game)

    if move.p1 != move.p2
        place_stone!(game, move.p2, -1)
    end

    place_stone!(game, move.p1, -1)
end

function next_turn!(game::Game)
    if game.stone == Black
        game.stone = White
        game.turn_idx = 2
    else
        game.stone = Black
        game.turn_idx = 1
    end
end

function place_stone!(game, place, coeff)
    x, y = place.x, place.y
    if coeff == 1
        game.value += game.values[game.turn_idx, x, y]
    else
        game.stones[x, y] = None
    end

    ms = max_stones(game.name)
    begin
        start_x = max(1, x - ms + 1)
        end_x = min(board_size - ms + 1, x)
        n = end_x - start_x + 1
        update_row!(game, start_x, y, 1, 0, n, coeff)
    end

    begin
        start_y = max(1, y - ms + 1)
        end_y = min(board_size - ms + 1, y)
        n = end_y - start_y + 1
        update_row!(game, x, start_y, 0, 1, n, coeff)
    end

    m = min(x, y, board_size + 1 - x, board_size + 1 - y)

    begin
        n = min(ms, m, board_size + 1 - ms - y + x, board_size + 1 - ms - x + y)
        if n > 0
            mn = min(x, y, ms)
            xStart = x - mn + 1
            yStart = y - mn + 1
            update_row!(game, xStart, yStart, 1, 1, n, coeff)
        end
    end

    begin
        n = min(ms, m, 2board_size + 2 - ms - y - x, x + y - ms)
        if n > 0
            mn = min(board_size + 1 - x, y, ms)
            xStart = x + mn - 1
            yStart = y - mn + 1
            update_row!(game, xStart, yStart, -1, 1, n, coeff)
        end
    end

    if coeff == 1
        game.stones[x, y] = game.stone
    else
        game.value -= game.values[game.turn_idx, x, y]
    end
end

function update_row!(game, x, y, dx, dy, n, coeff)
    ms1 = max_stones(game.name) - 1
    stones = 1
    for i in 0:max_stones(game.name)-2
        stones += game.stones[x+i*dx, y+i*dy]
    end
    for _ in 1:n
        stones += game.stones[x+ms1*dx, y+ms1*dy]
        b_value, w_value = game_values(game.name, game.stone, stones)
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

function top_moves(game, ::Name{:Gomoku}, moves)
    empty!(moves)
    top_places(game)

    has_draw = false
    for place in game.places
        value = game.values[game.turn_idx, place.x, place.y]
        if value < -win_value || value > win_value
            push!(moves, MoveValue(Move(place, place), value, true))
            return
        end

        if value != 0 || has_draw
            move = MoveValue(Move(place, place), game.value + value ÷ Int16(2), value == 0)
            push!(moves, move)
        end
        has_draw = has_draw || value == 0
    end
end

function top_moves(game, ::Name{:Connect6}, moves)
    less = game.stone == Black ? (a, b) -> a.value < b.value : (a, b) -> b.value < a.value

    empty!(moves)
    top_places(game)
    game_value = game.value

    has_draw = false

    for (i, place1) in enumerate(game.places)
        value1 = game.values[game.turn_idx, place1.x, place1.y]
        if value1 < -win_value || value1 > win_value
            heap_push!(moves, MoveValue(Move(place1, place1), game.value + value1, true), n_moves, less)
            return
        end

        place_stone!(game, place1, 1)

        for place2 in game.places[i+1:end]
            value2 = game.values[game.turn_idx, place2.x, place2.y]
            if value2 < -win_value || value2 > win_value
                heap_push!(moves, MoveValue(Move(place1, place2), game_value + (value1 + value2) ÷ Int16(2), true), n_moves, less)
                place_stone!(game, place1, -1)
                return
            end

            is_draw = value1 + value2 == 0
            if !is_draw || !has_draw
                mv = MoveValue(Move(place1, place2), game_value + (value1 + value2) ÷ Int16(2), is_draw)
                heap_push!(moves, mv, n_moves, less)
            end
            has_draw = has_draw || is_draw

        end

        place_stone!(game, place1, -1)

    end
end

function top_places(game)
    less = game.stone == Black ? (a, b) -> game.values[1, a.x, a.y] < game.values[1, b.x, b.y] :
           (a, b) -> game.values[2, b.x, b.y] < game.values[2, a.x, a.y]

    empty!(game.places)

    for y in 1:board_size, x in 1:board_size
        if game.stones[x, y] == None
            heap_push!(game.places, Place(x, y), n_places, less)
        end
    end
end

function board_value(game)
    result = Int16(0)
    ms = max_stones(game.name)
    for y in 1:board_size
        stones = 1
        for x in 1:ms-1
            stones += game.stones[x, y]
        end
        for x in 1:board_size-ms+1
            stones += game.stones[x+ms-1, y]
            result += stones_value(game.name, stones)
            stones -= game.stones[x, y]
        end
    end
    for x in 1:board_size
        stones = 1
        for y in 1:ms-1
            stones += game.stones[x, y]
        end
        for y in 1:board_size-ms+1
            stones += game.stones[x, y+ms-1]
            result += stones_value(game.name, stones)
            stones -= game.stones[x, y]
        end
    end
    for y in 1:board_size+1-ms
        stones = 1
        for x in 1:ms-1
            stones += game.stones[x, y+x-1]
        end
        for x in 1:board_size+2-ms-y
            stones += game.stones[x+ms-1, x+y+ms-2]
            result += stones_value(game.name, stones)
            stones -= game.stones[x, x+y-1]
        end
    end
    for x in 2:board_size+1-ms
        stones = 1
        for y in 1:ms-1
            stones += game.stones[x+y-1, y]
        end
        for y in 1:board_size+2-ms-x
            stones += game.stones[x+y+ms-2, y+ms-1]
            result += stones_value(game.name, stones)
            stones -= game.stones[x+y-1, y]
        end
    end
    for y in 1:board_size+1-ms
        stones = 1
        for x in 1:ms-1
            stones += game.stones[board_size+1-x, y+x-1]
        end
        for x in 1:board_size+2-ms-y
            stones += game.stones[board_size+2-x-ms, x+y+ms-2]
            result += stones_value(game.name, stones)
            stones -= game.stones[board_size+1-x, x+y-1]
        end
    end
    for x in 2:board_size+1-ms
        stones = 1
        for y in 1:ms-1
            stones += game.stones[board_size+2-x-y, y]
        end
        for y in 1:board_size+2-ms-x
            stones += game.stones[board_size+3-x-y-ms, y+ms-1]
            result += stones_value(game.name, stones)
            stones -= game.stones[board_size+2-x-y, y]
        end
    end

    result
end

# TODO: Use Unroll.jl?
# TODO: Use @inbounds?
function board_values(game)
    result = zeros(Int16, 2, board_size, board_size)
    ms = max_stones(game.name)
    for y in 1:board_size
        stones = 1
        for x in 1:ms-1
            stones += game.stones[x, y]
        end
        for x in 1:board_size+1-ms
            stones += game.stones[x+ms-1, y]
            for i in 0:ms-1
                b_value, w_value = stones_values(game.name, stones)
                result[1, x+i, y] += b_value
                result[2, x+i, y] += w_value
            end
            stones -= game.stones[x, y]
        end
    end
    for x in 1:board_size
        stones = 1
        for y in 1:ms-1
            stones += game.stones[x, y]
        end
        for y in 1:board_size-ms+1
            stones += game.stones[x, y+ms-1]
            for i in 0:ms-1
                b_value, w_value = stones_values(game.name, stones)
                result[1, x, y+i] += b_value
                result[2, x, y+i] += w_value
            end
            stones -= game.stones[x, y]
        end
    end
    for y in 1:board_size+1-ms
        stones = 1
        for x in 1:ms-1
            stones += game.stones[x, y+x-1]
        end
        for x in 1:board_size+2-ms-y
            stones += game.stones[x+ms-1, x+y+ms-2]
            for i in 0:ms-1
                b_value, w_value = stones_values(game.name, stones)
                result[1, x+i, x+y+i-1] += b_value
                result[2, x+i, x+y+i-1] += w_value
            end
            stones -= game.stones[x, x+y-1]
        end
    end
    for x in 2:board_size+1-ms
        stones = 1
        for y in 1:ms-1
            stones += game.stones[x+y-1, y]
        end
        for y in 1:board_size+2-ms-x
            stones += game.stones[x+y+ms-2, y+ms-1]
            for i in 0:ms-1
                b_value, w_value = stones_values(game.name, stones)
                result[1, x+y+i-1, y+i] += b_value
                result[2, x+y+i-1, y+i] += w_value
            end
            stones -= game.stones[x+y-1, y]
        end
    end
    for y in 1:board_size+1-ms
        stones = 1
        for x in 1:ms-1
            stones += game.stones[board_size+1-x, y+x-1]
        end
        for x in 1:board_size+2-ms-y
            stones += game.stones[board_size+2-x-ms, x+y+ms-2]
            for i in 0:ms-1
                b_value, w_value = stones_values(game.name, stones)
                result[1, board_size-x-i+1, x+y+i-1] += b_value
                result[2, board_size-x-i+1, x+y+i-1] += w_value
            end
            stones -= game.stones[board_size+1-x, x+y-1]
        end
    end
    for x in 2:board_size+1-ms
        stones = 1
        for y in 1:ms-1
            stones += game.stones[board_size+2-x-y, y]
        end
        for y in 1:board_size+2-ms-x
            stones += game.stones[board_size+3-x-y-ms, y+ms-1]
            for i in 0:ms-1
                b_value, w_value = stones_values(game.name, stones)
                result[1, board_size+2-x-y-i, y+i] += b_value
                result[2, board_size+2-x-y-i, y+i] += w_value
            end
            stones -= game.stones[board_size+2-x-y, y]
        end
    end
    result
end

function parse_move(move)
    tokens = split(move, '-')
    p1 = parse_place(tokens[begin])

    if length(tokens) == 1
        return Move(p1, p1)
    end
    p2 = parse_place(tokens[end])
    Move(p1, p2)
end

function parse_place(place)
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
        y = 10y + place[3] - '0'
    end
    y = board_size + 1 - y
    if x > board_size || y > board_size
        throw(ArgumentError("Invalid Place"))
    end
    Place(x, y)
end

game_values(::Name{:Gomoku}, stone, stones) =
    stone == Black ? gomoku_first[stones] : gomoku_second[stones]

game_values(::Name{:Connect6}, stone, stones) =
    stone == Black ? connect6_first[stones] : connect6_second[stones]

stones_values(::Name{:Connect6}, stones) = connect6_values[stones]
stones_values(::Name{:Gomoku}, stones) = gomoku_values[stones]

stones_value(::Name{:Connect6}, stones) = connect6_value[stones]
stones_value(::Name{:Gomoku}, stones) = gomoku_value[stones]
