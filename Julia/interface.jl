const debug = Val(true)

const size = Int8(19)

abstract type Turn end
struct First <: Turn end
struct Second <: Turn end

struct MoveValue{Move}
    move::Move
    value::Int16
    isterminal::Bool
end