from score import Score
from traits import TTree, TGame, TMove, MoveScore


struct Tree[G: TGame, n_leaves: Int](TTree, Representable, Stringable, Writable):
    alias Game = Self.G

    var nodes: List[Node[Self.G.Move]]
    var leaves: List[NodeIdScore]
    var heap: List[NodeIdScore]
    var free: NodeId

    fn __init__(out self):
        self.nodes = List(Node[Self.G.Move](Self.G.Move()))
        self.leaves = List[NodeIdScore](capacity=Self.n_leaves)
        self.leaves.append(NodeIdScore(root_id, Score()))
        self.heap = List[NodeIdScore](capacity=Self.n_leaves)
        self.free = null_id

    fn search(mut self, game: Self.Game, max_time_ms: UInt) -> MoveScore[Self.Game.Move]:
        return MoveScore(Self.Game.Move(), Score())

    fn alloc_node(mut self, move: Self.G.Move, /, parent: NodeId = null_id, first_child: NodeId = null_id, next_sibling: NodeId = null_id) -> ref [self.nodes] Node[Self.G.Move]:
        if self.free != null_id:
            var id = self.free
            self.free = self.nodes[id].next_sibling
            ref result = self.nodes[id]
            result.move = move
            result.active = True
            result.parent = parent
            result.first_child = first_child
            result.next_sibling = next_sibling
            return result
        else:
            self.nodes.append(Node(move, parent=parent, first_child=first_child, next_sibling=next_sibling))
            return ref self.nodes[-1]

    fn free_node(mut self, parent: NodeId):
        var id = self.nodes[parent].first_child
        while True:
            if id == null_id:
                break
            else:
                self.free_node(id)
                id = self.nodes[id].next_sibling
        self.nodes[id].active = False
        self.nodes[id].next_sibling = self.free
        self.free = id

    fn reset(mut self):
        self.free_node(root_id)
        self.leaves.clear()
        self.leaves.append(NodeIdScore(root_id, Score()))
        self.nodes.clear()

    fn __repr__(self, out str: String):
        return String.write(self)

    fn __str__(self, out str: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        ...

alias NodeId = UInt32
alias null_id = UInt32.MAX
alias root_id = UInt32()


@register_passable
struct Node[Move: TMove](Copyable, Movable):
    var move: Self.Move
    var active: Bool
    var parent: NodeId
    var first_child: NodeId
    var next_sibling: NodeId

    fn __init__(out self, move: Self.Move, /, parent: NodeId = null_id, first_child: NodeId = null_id, next_sibling: NodeId = null_id):
        self.move = move
        self.active = True
        self.parent = parent
        self.first_child = first_child
        self.next_sibling = next_sibling


@register_passable
@fieldwise_init
struct NodeIdScore(ImplicitlyCopyable, Movable, Representable, Stringable, Writable):
    var node_id: NodeId
    var score: Score

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.node_id)
        if self.score.is_win():
            writer.write(" win")
        elif self.score.is_loss():
            writer.write(" loss")
        elif self.score.is_draw():
            writer.write(" draw")
        else:
            writer.write(" ", self.score)


fn main():
    pass
