#!/usr/bin/env julia

include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")
include("tree.jl")
include("engine.jl")

run_engine(connect6)
