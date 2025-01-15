struct Node{Move}
    children::Vector{Node{Move}}
    n_sims::Int32
    value::Int16
    isdecisive::Bool
    isterminal::Bool
    move::Move

    function Node{Move}(
        move::Move;
        children::Vector{Node{Move}}=Node{Move}[],
        value::Int16=Int16(0),
        n_sims::Int32=Int32(1),
        isdecisive::Bool=false,
        isterminal::Bool=false,
    ) where {Move}
        new(children, n_sims, value, isdecisive, isterminal, move)
    end
end

mutable struct Tree{Move}
    max_moves::Int
    exploration_factor::Float64

    root::Node{Move}
    top_moves::Vector{MoveValue{Move}}

    Tree{Move}(max_moves::Int, exploration_factor::Float64) where {Move} =
        new{Move}(max_moves, exploration_factor, Node{Move}(Move()), MoveValue{Move}[])
end

function expand(tree::Tree{Move}, game) where {Move}
    expand(tree, tree.root, game)
    validate(tree, debug)
end

function expand(tree::Tree{Move}, node::Node{Move}, game)::Node{Move} where {Move}
    println("expand: node")
    if node.isdecisive
        return Node{Move}(Node{Move}[], node.value, node.n_sims + tree.max_moves, node.move, node.isdecisive, node.isterminal)
    end

    if isempty(node.children)
        top_moves(game, tree.top_moves, tree.max_moves)

        children = Vector{Node{Move}}(undef, length(tree.max_moves))
        for (i, child_move) in enumerate(tree.top_moves)
            node = Node{Move}(child_move.move)
            children[i] = node
        end
        return update_stats(tree, Node{Move}(node.move, children=children))
    else
        selected_child = select_child(node, turn(tree.game), tree.exploration_factor)
        play_move(game, selected_child.move)
        expand(tree, selected_child)
        undo_move(game, selected_child.move)
        return update_stats(tree, node)
    end
end

function update_stats(tree::Tree{Move}, node::Node{Move})::Node{Move} where {Move}
    dump(tree)
    dump(node)
    return node
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
