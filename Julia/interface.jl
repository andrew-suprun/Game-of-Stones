const debug = Val(true)

abstract type Turn end
struct First <: Turn end
struct Second <: Turn end

next(turn::Turn)::Turn =
    if (turn == First())
        Second()
    else
        First()
    end
