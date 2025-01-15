include("interface.jl")

struct Place
    x::Int8
    y::Int8
end

struct Move
    p1::Place
    p2::Place
    value::Float32
    isdecisive::Bool
    isterminal::Bool
end

const None = Int8(0)
const Black = Int8(1)
const White = Int8(6)


mutable struct Game
    stone::Int8
    turn::Turn
end

function top_moves(game::Game, moves::Vector{Move}, max_moves::Int) where {Move}
    push!(moves, TestMove())
end
