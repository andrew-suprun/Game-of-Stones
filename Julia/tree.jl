struct Node{Move}
    children::Vector{Node{Move}}
    move::Move
    n_sims::Int32
end

mutable struct Tree{Move}
    max_moves::Int
    exploration_factor::Float64

    root::Node{Move}
    top_moves::Vector{Move}

    Tree{Move}(max_moves::Int, exploration_factor::Float64) where {Move} =
        new(max_moves, exploration_factor, Node{Move}(Node[], Move(), 0), Move[])
end

function expand(tree::Tree{Move}, game) where {Move}
    expand(tree, tree.root, game)
    validate(tree, debug)
end

function expand(tree::Tree{Move}, node::Node{Move}, game)::Node{Move} where {Move}
    println("expand: node")
    if isdecisive(node.move)
        return Node(Node[], node.move, node.n_sims + tree.max_moves)
        return
    end


    if isempty(node.children)
        top_moves(game, tree.top_moves, tree.max_moves)

        children = Vector{Node{Move}}(undef, length(tree.max_moves))
        for (i, child_move) in enumerate(tree.top_moves)
            node = Node{Move}(Node[], child_move, Int32(1))
            children[i] = node
        end
        return update_stats(tree, Node{Move}(children, node.move, 0))
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
