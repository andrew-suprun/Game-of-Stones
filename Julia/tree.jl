struct Node
    first_child::UInt32
    n_sims::Int32
    value::Int16
    n_children::UInt8
    decision::Decision

    Node(;
        first_child=UInt32(0),
        n_children=UInt8(0),
        n_sims=Int32(1),
        value=Int16(0),
        decision=no_decision,
    ) = new(first_child, n_sims, value, n_children, decision)
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
    first_child = tree.nodes[1].first_child
    last_child = first_child + tree.nodes[1].n_children - 1
    for i in first_child:last_child
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
            n_children=parent.n_children,
            n_sims=parent.n_sims + n_moves,
            value=parent.value,
            decision=parent.decision)
        return
    end

    if parent.n_children == 0
        top_moves(game, tree.top_moves)
        if isempty(tree.top_moves)
            error("Function top_moves(game, ...) returns empty result.")
        end

        tree.nodes[parent_idx] = Node(first_child=length(tree.nodes) + 1, n_children=length(tree.top_moves))
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
        w_win = true
        all_draws = true
        for i in node.first_child:node.first_child+node.n_children-1
            child = tree.nodes[i]
            n_sims += child.n_sims
            value = max(value, child.value)
            if child.decision == black_win
                decision = black_win
                return Node(first_child=node.first_child, n_children=node.n_children, n_sims=n_sims, value=value, decision=black_win)
            end
            w_win = w_win && child.decision == white_win
            all_draws = all_draws && child.decision == draw
        end
        decision = w_win ? white_win : all_draws ? draw : no_decision
    else
        b_win = true
        all_draws = true
        for i in node.first_child:node.first_child+node.n_children-1
            child = tree.nodes[i]
            n_sims += child.n_sims
            value = min(value, child.value)
            if child.decision == white_win
                decision = white_win
                return Node(first_child=node.first_child, n_children=node.n_children, n_sims=n_sims, value=value, decision=white_win)
            end
            b_win = b_win && child.decision == black_win
            all_draws = all_draws && child.decision == draw
        end
        decision = b_win ? black_win : all_draws ? draw : no_decision
    end

    return Node(first_child=node.first_child, n_children=node.n_children, n_sims=n_sims, value=value, decision=decision)
end

function select_child(tree, node, stone, exploration_factor)
    coeff = stone == black ? 1 : -1
    selected_child_idx = 1
    log_parent_sims = log(node.n_sims)
    max_value = -Inf
    for idx in node.first_child:node.first_child+node.n_children-1
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
        for i in root.first_child:root.first_child+root.n_children-1
            best = tree.nodes[best_child_idx]
            node = tree.nodes[i]
            if best.decision == black_win
                if node.decision == black_win && best.n_sims < node.n_sims
                    best_child_idx = i
                end
            elseif best.decision == white_win
                if node.decision != white_win
                    best_child_idx = i
                elseif best.n_sims < node.n_sims
                    best_child_idx = i
                end
            elseif node.decision == black_win || best.value < node.value
                best_child_idx = i
            else
            end
        end
    else
        for i in root.first_child:root.first_child+root.n_children-1
            best = tree.nodes[best_child_idx]
            node = tree.nodes[i]
            if best.decision == white_win
                if node.decision == white_win && best.n_sims < node.n_sims
                    best_child_idx = i
                end
            elseif best.decision == black_win
                if node.decision != black_win
                    best_child_idx = i
                elseif best.n_sims < node.n_sims
                    best_child_idx = i
                end
            elseif node.decision == white_win || best.value > node.value
                best_child_idx = i
            end
        end
    end

    return tree.moves[best_child_idx]
end

Base.show(io::IO, tree::Tree{Move}) where {Move} = print_node(io, tree, 1, 0)
Base.show(io::IO, node::Node) = print(io, "first_child=$(node.first_child) n_children=$(node.n_children) value=$(node.value) decision=$(node.decision) n_sims=$(node.n_sims)")

function print_node(io::IO, tree, node_idx, depth)
    node = tree.nodes[node_idx]
    move = tree.moves[node_idx]
    print(io, "|   "^depth, "$(move) v:$(node.value) sims:$(node.n_sims)")
    if node.decision != no_decision
        println(io, " decisive")
    else
        println(io)
    end
    for child_idx in node.first_child:node.first_child+node.n_children-1
        print_node(io, tree, child_idx, depth + 1)
    end
end
