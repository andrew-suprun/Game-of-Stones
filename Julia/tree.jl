struct Node{Move}
    children::Vector{Node{Move}}
    n_sims::Int32
    value::Int16
    decision::Decision
    terminal::Decision
    move::Move

    function Node{Move}(move; children=Node{Move}[], value=Int16(0), n_sims=Int32(1),
        decision=no_decision, terminal=no_decision,
    ) where {Move}
        new(children, n_sims, value, decision, terminal, move)
    end
end

mutable struct Tree{Move}
    exploration_factor::Float64

    root::Node{Move}
    top_moves::Vector{MoveValue{Move}}

    Tree{Move}(exploration_factor) where {Move} =
        new{Move}(exploration_factor, Node{Move}(Move()), MoveValue{Move}[])
end

function expand!(tree, game)
    tree.root = expand!(tree, tree.root, game)
    validate(tree, debug)
end

function expand!(tree, node, game)
    if node.decision != no_decision
        return Node{Move}(node.move,
            children=node.children,
            n_sims=node.n_sims + n_moves,
            value=node.value,
            decision=node.decision,
            terminal=node.terminal)
    end

    if isempty(node.children)
        top_moves(game, tree.top_moves)

        children = Vector{Node{Move}}(undef, length(tree.top_moves))
        for (i, child_move) in enumerate(tree.top_moves)
            children[i] = Node{Move}(
                child_move.move,
                value=child_move.value,
                decision=child_move.terminal,
                terminal=child_move.terminal,
            )
        end
        return update_stats(Node{Move}(node.move, children=children), game.turn_idx)
    else
        idx = select_child(node, game.turn_idx, tree.exploration_factor)
        move = node.children[idx].move
        play_move!(game, move)
        node.children[idx] = expand!(tree, node.children[idx], game)
        undo_move!(game, move)
        return update_stats(node, game.turn_idx)
    end
end

function select_child(node, turn_idx, exploration_factor)
    coeff = turn_idx == 1 ? 1 : -1
    selected_child_idx = 1
    log_parent_sims = log(node.n_sims)
    max_value = -Inf
    for (idx, child) in enumerate(node.children)
        value = coeff * child.value + exploration_factor * sqrt(log_parent_sims / child.n_sims)
        if max_value < value
            max_value = value
            selected_child_idx = idx
        end
    end
    child = node.children[selected_child_idx]
    return selected_child_idx
end

function update_stats(node, turn_idx)
    n_sims = Int32(0)
    value = node.children[begin].value
    decision = no_decision
    if turn_idx == 1
        b_win = false
        w_win = true
        all_draws = true
        for child in node.children
            n_sims += child.n_sims
            value = max(value, child.value)
            b_win = b_win || child.decision == black_win
            w_win = w_win && child.decision == white_win
            all_draws = all_draws && child.decision == draw
        end
        decision = b_win ? black_win : all_draws ? draw : w_win ? white_win : no_decision
    else
        b_win = true
        w_win = false
        all_draws = true
        for child in node.children
            n_sims += child.n_sims
            value = min(value, child.value)
            b_win = b_win && child.decision == black_win
            w_win = w_win || child.decision == white_win
            all_draws = all_draws && child.decision == draw
            decision = w_win ? white_win : all_draws ? draw : b_win ? black_win : no_decision
        end
    end
    return Node{Move}(node.move, children=node.children, value=value, n_sims=n_sims, decision=decision, terminal=no_decision)
end

function commit_move!(tree, game, to_play)
    move = parse_move(to_play)
    play_move!(game, move)
    for child in tree.root.children
        if move == child.move
            tree.root = child
            expand!(tree, game)
            return
        end
    end
    tree.root = Node{Move}(Move(), value=board_value(game))
    expand!(tree, game)
end

function best_move(tree, game)
    for child in tree.root.children
        println("$(child.move) | v: $(child.value) | s: $(child.n_sims) d: $(child.decision)")
    end

    best_child = tree.root.children[1]
    if game.stone == black
        for child in tree.root.children
            if best_child.value < child.value
                best_child = child
            end
        end
    else
        for child in tree.root.children
            if best_child.value > child.value
                best_child = child
            end
        end
    end
    return best_child.move
end

Base.show(io::IO, tree::Tree{Move}) where {Move} = Base.show(io, tree.root)
Base.show(io::IO, node::Node{Move}) where {Move} = print_node(io, node, 0)

function print_node(io::IO, node::Node{Move}, depth) where {Move}
    print(io, "|   "^depth, "$(node.move) v:$(node.value) sims:$(node.n_sims)")
    if node.terminal != no_decision
        println(io, " terminal")
    elseif node.decision != no_decision
        println(io, " decisive")
    else
        println(io)
    end
    for child in node.children
        print_node(io, child, depth + 1)
    end
end

function validate(tree::Tree, debug::Debug{true})
    error("TODO: Implement")
end

validate(tree::Tree, debug::Debug{false}) = nothing
