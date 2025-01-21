using Test

include("heap.jl")

less(i, j) = i < j

function test_heap()
    heap = Vector{Int8}()
    items = rand(Int8, 100)
    for item in items
        heap_push!(heap, item, 20, less)
    end
    length(heap) == 20 || return false
    for i in 2:20
        heap[i÷2] <= heap[i] || return false
    end
    return true
end

@test test_heap()