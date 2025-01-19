struct Node{Move}
    children::Vector{Node{Move}}
    n_sims::Int32
    value::Int16
    isdecisive::Bool
    isterminal::Bool
    move::Move

    function Node{Move}(move; children=Node{Move}[], value=Int16(0), n_sims=Int32(1),
        isdecisive=false, isterminal=false,
    ) where {Move}
        new(children, n_sims, value, isdecisive, isterminal, move)
    end
end

mutable struct Tree{Move}
    max_moves::Int
    exploration_factor::Float64

    root::Node{Move}
    top_moves::Vector{MoveValue{Move}}

    Tree{Move}(max_moves, exploration_factor) where {Move} =
        new{Move}(max_moves, exploration_factor, Node{Move}(Move()), MoveValue{Move}[])
end

function expand(tree, game) where {Move}
    expand(tree, tree.root, game)
    validate(tree, debug)
end

function expand(tree, node, game)
    println("expand: node")
    if node.isdecisive
        return Node{Move}(Node{Move}[], node.value, node.n_sims + tree.max_moves, node.move, node.isdecisive, node.isterminal)
    end

    if isempty(node.children)
        top_moves(game, tree.top_moves, tree.max_moves)

        children = Vector{Node{Move}}(undef, length(tree.max_moves))
        for (i, child_move) in enumerate(tree.top_moves)
            children[i] = Node{Move}(
                child_move.move,
                value=child_move.value,
                isterminal=child_move.isterminal,
            )
        end
        return update_stats(Node{Move}(node.move, children=children), game.turn)
    else
        selected_child = select_child(node, turn(tree.game), tree.exploration_factor)
        play_move(game, selected_child.move)
        expand(tree, selected_child)
        undo_move(game, selected_child.move)
        return update_stats(node, game.turn)
    end
end

function update_stats(node, turn) where {Move}
    n_sims = Int32(0)
    value = node.children[begin].value
    isdecisive = false
    if turn == :First
        for child in node.children
            n_sims += child.n_sims
            value = max(value, child.value)
            isdecisive = isdecisive || child.isdecisive && child.value > 0
        end
    else
        for child in node.children
            n_sims += child.n_sims
            value = min(value, child.move.Value())
            isdecisive = isdecisive || child.isdecisive && child.value < 0
        end
    end
    Node{Move}(node.move, children=node.children, value=value, n_sims=n_sims, isdecisive=isdecisive, isterminal=false)
end

function commit_move(tree, game, name, to_play) where {Move}
    move = parse_move(to_play)
    play_move(game, move)
    for child in root.children
        if move == child.move
            tree.root = child
            return
        end
    end
    tree.root = Node{Move}(Move(), value=board_value(game, name))
end

function best_move(tree)
    error("TODO: Implement")
end

function show(io::IO, tree::Tree)
    error("TODO: Implement")
end

function validate(tree::Tree, debug::Val{true})
    error("TODO: Implement")
end

validate(tree::Tree, debug::Val{false}) = nothing
