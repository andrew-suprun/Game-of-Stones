include("interface.jl")

struct Place
    x::Int8
    y::Int8
end

struct Move
    p1::Place
    p2::Place
end

Move() = Move(Place(0, 0), Place(0, 0))

const None = Int8(0)
const Black = Int8(1)
const White = Int8(6)


mutable struct Game
    stone::Int8
    turn::Turn
end

function top_moves(game::Game, moves::Vector{MoveValue{Move}}, max_moves::Int)
    push!(moves, MoveValue(Move(Place(1, 2), Place(3, 4)), Int16(0), false))
end
