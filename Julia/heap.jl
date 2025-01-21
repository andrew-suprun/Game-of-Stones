function heap_push!(heap, item, size, less)
    if length(heap) == size
        less(heap[1], item) || return
        heap[1] = item
        sift_down(heap, less)
        return
    end
    push!(heap, item)
    sift_up(heap, less)
end

function sift_up(heap, less)
    child_idx = length(heap)
    child = heap[child_idx]
    while child_idx > 1 && less(child, heap[child_idx÷2])
        parent_idx = child_idx ÷ 2
        parent = heap[parent_idx]
        heap[child_idx] = parent
        child_idx = parent_idx
    end
    heap[child_idx] = child
end

function sift_down(heap, less)
    idx = 1
    item = heap[idx]
    while true
        first = idx
        left_child_idx = 2idx
        if left_child_idx <= length(heap) && less(heap[left_child_idx], item)
            first = left_child_idx
        end
        right_child_idx = 2idx + 1
        if right_child_idx <= length(heap) &&
           less(heap[right_child_idx], item) &&
           less(heap[right_child_idx], heap[left_child_idx])
            first = right_child_idx
        end
        idx != first || break
        heap[idx] = heap[first]
        idx = first
    end
    heap[idx] = item
end
