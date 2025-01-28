struct Node
    first_child::UInt32
    last_child::Int32
    n_sims::UInt32
    value::Int16
    decision::Decision

    Node(;
        first_child=UInt32(0),
        last_child=UInt32(0),
        n_sims=Int32(1),
        value=Int16(0),
        decision=no_decision,
    ) = new(first_child, last_child, n_sims, value, decision)
end

mutable struct Tree{Move}
    exploration_factor::Float64
    nodes::Vector{Node}
    moves::Vector{Move}
    top_moves::Vector{MoveValue{Move}}

    function Tree{Move}(exploration_factor) where {Move}
        new{Move}(exploration_factor, [Node()], [Move()], Vector{MoveValue}())
    end
end

function expand!(tree, game)
    expand!(tree, game, 1)
    if tree.nodes[1].decision != no_decision
        return false
    end
    undecided = 0
    root = tree.nodes[1]
    for i in root.first_child:root.last_child
        if tree.nodes[i].decision == no_decision
            undecided += 1
        end
    end
    undecided > 1
end

function expand!(tree, game, parent_idx)
    parent = tree.nodes[parent_idx]
    if parent.decision != no_decision
        tree.nodes[parent_idx] = Node(
            first_child=parent.first_child,
            last_child=parent.last_child,
            n_sims=parent.n_sims + n_moves,
            value=parent.value,
            decision=parent.decision)
        return
    end

    if parent.first_child == 0
        top_moves(game, tree.top_moves)
        if isempty(tree.top_moves)
            error("Function top_moves(game, ...) returns empty result.")
        end

        first_child = length(tree.nodes) + 1
        last_child = first_child + length(tree.top_moves) - 1
        tree.nodes[parent_idx] = Node(first_child=first_child, last_child=last_child)
        for child_move_value in tree.top_moves
            child_node = Node(value=child_move_value.value, decision=child_move_value.terminal)
            push!(tree.nodes, child_node)
            push!(tree.moves, child_move_value.move)
        end
    else
        idx = select_child(tree, parent, game.stone, tree.exploration_factor)
        parent = tree.nodes[idx]
        move = tree.moves[idx]
        play_move!(game, move)
        expand!(tree, game, idx)
        undo_move!(game, move)
    end
    tree.nodes[parent_idx] = update_stats(tree, tree.nodes[parent_idx], game.stone)
end

function update_stats(tree, node, stone)
    n_sims = Int32(0)
    value = tree.nodes[node.first_child].value
    decision = no_decision
    if stone == black
        b_win = false
        w_win = true
        all_draws = true
        for i in node.first_child:node.last_child
            child = tree.nodes[i]
            n_sims += child.n_sims
            value = max(value, child.value)
            if child.decision == first_win
                b_win = true
            end
            w_win = w_win && child.decision == second_win
            all_draws = all_draws && child.decision == draw
        end
        decision = b_win ? first_win : w_win ? second_win : all_draws ? draw : no_decision
    else
        w_win = false
        b_win = true
        all_draws = true
        for i in node.first_child:node.last_child
            child = tree.nodes[i]
            n_sims += child.n_sims
            value = min(value, child.value)
            if child.decision == second_win
                w_win = true
            end
            b_win = b_win && child.decision == first_win
            all_draws = all_draws && child.decision == draw
        end
        decision = w_win ? second_win : b_win ? first_win : all_draws ? draw : no_decision
    end

    return Node(first_child=node.first_child, last_child=node.last_child, n_sims=n_sims, value=value, decision=decision)
end

function select_child(tree, node, stone, exploration_factor)
    coeff = stone == black ? 1 : -1
    selected_child_idx = 1
    log_parent_sims = log(node.n_sims)
    max_value = -Inf
    for idx in node.first_child:node.last_child
        child = tree.nodes[idx]
        if child.decision == no_decision
            value = coeff * child.value + exploration_factor * sqrt(log_parent_sims / child.n_sims)
            if max_value < value
                max_value = value
                selected_child_idx = idx
            end
        end
    end
    return selected_child_idx
end

function commit_move!(tree, game, to_play)
    move = parse_move(to_play)
    play_move!(game, move)
    empty!(tree.nodes)
    empty!(tree.moves)
    node = Node(value=board_value(game), decision=decision(game)[1])
    push!(tree.nodes, node)
    push!(tree.moves, move)
end

function best_move(tree, game)
    root = tree.nodes[1]
    best_child_idx = root.first_child

    if game.stone == black
        for i in root.first_child:root.last_child
            best = tree.nodes[best_child_idx]
            node = tree.nodes[i]
            if best.decision == first_win
                if node.decision == first_win && best.n_sims < node.n_sims
                    best_child_idx = i
                end
            elseif best.decision == second_win
                if node.decision != second_win || best.n_sims < node.n_sims
                    best_child_idx = i
                end
            elseif node.decision == first_win || best.value < node.value
                best_child_idx = i
            else
            end
        end
    else
        for i in root.first_child:root.last_child
            best = tree.nodes[best_child_idx]
            node = tree.nodes[i]
            if best.decision == second_win
                if node.decision == second_win && best.n_sims < node.n_sims
                    best_child_idx = i
                end
            elseif best.decision == first_win
                if node.decision != first_win || best.n_sims < node.n_sims
                    best_child_idx = i
                end
            elseif node.decision == second_win || best.value > node.value
                best_child_idx = i
            end
        end
    end

    return tree.moves[best_child_idx]
end

Base.show(io::IO, tree::Tree{Move}) where {Move} = print_node(io, tree, 1, 0)
Base.show(io::IO, node::Node) = print(io, "first_child=$(node.first_child) n_children=$(node.last_child-node.first_child+1) value=$(node.value) decision=$(node.decision) n_sims=$(node.n_sims)")

function print_node(io::IO, tree, node_idx, depth)
    node = tree.nodes[node_idx]
    move = tree.moves[node_idx]
    print(io, "|   "^depth, "$(move) v:$(node.value) sims:$(node.n_sims)")
    if node.decision != no_decision
        println(io, " decisive")
    else
        println(io)
    end
    for child_idx in node.first_child:node.last_child
        print_node(io, tree, child_idx, depth + 1)
    end
end
