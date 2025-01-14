import Base: show

const debug = Val(true)

struct MoveValue{Move}
    move::Move
    value::Float32
end

struct Node{Move}
    move::Move
    value::Float32
    n_sims::Int32
    children::Vector{Node}
end

mutable struct Tree{Move}
    game
    max_moves::Int
    exploration_factor::Float64

    root::Node{Move}
    top_moves::Vector{MoveValue}

    Tree{Move}(game, max_moves::Int, exploration_factor::Float64) where {Move} = new(game, max_moves, exploration_factor, Node{Move}(), [])
end

function expand(tree::Tree{Move}) where {Move}
    expand(tree, tree.root)
    validate(tree, debug)
end

function expand(tree::Tree{Move}, node::Node{Move}) where {Move}
    println("expand: node")
    if isdecisive(node.move)
        node.n_sims += tree.max_moves
        if !isempty(node.children)
            update_stats(tree, node)
        end
        return
    end

    if isempty(node.children)
        top_moves(tree.game, tree.top_moves, tree.max_moves)
        node.children = Vector{Move}(undef, length(tree.max_moves))
        for (i, child_move) in enumerate(tree.top_moves)
            node.children[i] = Node(child_move, tree.top_moves.value, 1, [])
        end
    else
        selected_child = select_child(node, turn(tree.game), tree.exploration_factor)
        play_move(tre.game, selected_child.move)
        expand(tree, selected_child)
        undo_move(tre.game, selected_child.move)
    end

    updateStats(tree, node)
end

function commit_move(tree::Tree)
end

function best_move(tree::Tree)::Move

end

function show(io::IO, tree::Tree)

end

function validate(tree::Tree, debug::Val{true})
    println("### Validate ###")
end

validate(tree::Tree, debug::Val{false}) = nothing


# Test
struct TestMove end
isdecisive(::TestMove) = false
tree = Tree{TestMove}(nothing, 3, 20.0)
expand(tree)

