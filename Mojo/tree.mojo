from math import log2, sqrt


from scores import Score, is_decisive, is_win, is_loss, is_draw, win, loss, draw
import game


@value
struct Node(CollectionElement, Stringable, Writable):
    var move: game.Move
    var value: Score
    var first_child: Int
    var last_child: Int
    var n_sims: Int

    fn __init__(out self, move: game.Move, value: Score):
        self.move = move
        self.value = value
        self.first_child = -1
        self.last_child = -1
        self.n_sims = 1

    fn __str__(self, out result: String):
        result = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " v: ", self.value)
        if self.first_child != -1:
            writer.write(" [", self.first_child, ":", self.last_child, "]")


struct Tree[Game: game.Game](Stringable, Writable):
    var c: Score
    var nodes: List[Node]
    var top_moves: List[game.MoveScore]
    var top_values: List[Score]

    fn __init__(out self, c: Score):
        self.c = c
        self.nodes = List[Node](Node(game.Move(0, 0, 0, 0), 0))
        self.top_moves = List[game.MoveScore]()
        self.top_values = List[Score]()

    fn expand(mut self, mut game: Game, out done: Bool):
        var root = self.nodes[0]
        if is_decisive(root.value):
            done = True
            return
        else:
            self._expand(game, 0)

        var undecided = 0
        for i in range(root.first_child, root.last_child):
            var child = self.nodes[i]
            if not is_decisive(child.value):
                if child.n_sims > 1:
                    undecided += 1
                else:
                    done = False
                    return
        done = undecided == 1

    fn _expand(mut self, mut game: Game, parent_idx: Score):
        var parent = self.nodes[parent_idx]
        var first_child = parent.first_child
        var last_child = parent.last_child
        var children = range(first_child, last_child)
        if first_child == -1:
            game.top_moves(self.top_moves)
            debug_assert(len(self.top_moves) > 0, "Function game.top_moves(...) returns empty result.")

            self.nodes[parent_idx].first_child = len(self.nodes)
            for idx in range(len(self.top_moves)):
                self.nodes.append(Node(self.top_moves[idx].move, self.top_moves[idx].score))
            self.nodes[parent_idx].last_child = len(self.nodes)
        else:
            var selected_child_idx = -1
            var n_sims = parent.n_sims
            var log_parent_sims = log2(Score(n_sims))
            var maxV = loss
            for idx in children:
                var child = self.nodes[idx]
                if is_decisive(child.value):
                    continue
                var v = child.value + self.c * sqrt(log_parent_sims / Score(child.n_sims))
                if v > maxV:
                    maxV = v
                    selected_child_idx = idx
            debug_assert(selected_child_idx > 0, "Failed to select a child.")
            var move = self.nodes[selected_child_idx].move
            game.play_move(move)
            self._expand(game, selected_child_idx)
            game.undo_move()

        self.nodes[parent_idx].n_sims = 0
        self.nodes[parent_idx].value = win
        var has_draw = False
        var all_draws = True
        for i in range(self.nodes[parent_idx].first_child, self.nodes[parent_idx].last_child):
            var child = self.nodes[i]
            if is_win(child.value):
                self.nodes[parent_idx].value = -child.value
                return
            elif is_draw(child.value):
                has_draw = True
                continue
            elif is_loss(child.value):
                continue
            all_draws = False
            self.nodes[parent_idx].n_sims += child.n_sims
            if self.nodes[parent_idx].value >= -child.value:
                self.nodes[parent_idx].value = -child.value
        if all_draws:
            self.nodes[parent_idx].value = draw
        elif has_draw and self.nodes[parent_idx].value > 0:
            self.nodes[parent_idx].value = 0

    fn best_move(self, out result: game.Move):
        var first_child = Int(self.nodes[0].first_child)
        var last_child = Int(self.nodes[0].last_child)
        var best_child = self.nodes[first_child]
        for child in self.nodes[first_child:last_child]:
            if best_child.value < child[].value:
                best_child = child[]
        result = best_child.move

    fn play_move(mut self, move: game.Move):
        var idx = -1
        var first_child = Int(self.nodes[0].first_child)
        var last_child = Int(self.nodes[0].last_child)
        for child_idx in range(first_child, last_child):
            if self.nodes[child_idx].move == move:
                idx = child_idx
                break

        if idx != -1:
            var new_nodes = List[Node](self.nodes[idx])
            var new_idx = 0
            while new_idx < len(new_nodes):
                var old_first_child = new_nodes[new_idx].first_child
                var old_last_child = new_nodes[new_idx].last_child
                if old_first_child == -1:
                    new_idx += 1
                    continue
                new_nodes[new_idx].first_child = len(new_nodes)
                new_nodes.extend(self.nodes[Int(old_first_child) : Int(old_last_child)])
                new_nodes[new_idx].last_child = len(new_nodes)
                new_idx += 1

            self.nodes = new_nodes
            return

        self.nodes.clear()
        self.nodes.append(Node(game.Move(0, 0, 0, 0), 0))

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0, 0)

    fn write_to[W: Writer](self, mut writer: W, idx: Score, depth: Int):
        writer.write("|   " * depth, self.nodes[idx], "\n")
        var parent = self.nodes[idx]
        if parent.first_child != -1:
            for child_idx in range(parent.first_child, parent.last_child):
                self.write_to(writer, child_idx, depth + 1)
