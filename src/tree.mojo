from score import Score
from traits import TTree, TGame, TMove, MoveScore


struct Tree[G: TGame, n_leaves: Int](TTree, Representable, Stringable, Writable):
    alias Game = Self.G

    var nodes: List[Node[Self.G.Move]]
    var leaves: List[NodeIdScore]
    var heap: List[NodeIdScore]
    var free: NodeId

    fn __init__(out self):
        self.nodes = List(Node(Self.G.Move(), Score.loss(), parent_id=null_id))
        self.leaves = List[NodeIdScore](capacity=Self.n_leaves)
        self.leaves.append(NodeIdScore(root_id, Score.loss()))
        self.heap = List[NodeIdScore](capacity=Self.n_leaves)
        self.free = null_id

    fn __getitem__(ref self, id: NodeId) -> ref [self.nodes] Node[Self.G.Move]:
        return self.nodes[id]

    fn search(mut self, game: Self.Game, max_time_ms: UInt) -> MoveScore[Self.Game.Move]:
        return MoveScore(Self.Game.Move(), Score())

    fn alloc_node(mut self, move: Self.G.Move, score: Score, /, parent_id: NodeId) -> NodeId:
        if self.free != null_id:
            var child_id = self.free
            self.free = self.nodes[child_id].next_sibling
            ref child = self.nodes[child_id]
            child.move = move
            child.score = score
            child.parent = parent_id
            child.first_child = null_id
            if parent_id != null_id:
                ref parent = self[parent_id]
                child.next_sibling = parent.first_child
                parent.first_child = child_id
            else:
                child.next_sibling = null_id
            return child_id
        else:
            self.nodes.append(Node(move, score, parent_id=parent_id))
            var child_id = len(self.nodes)
            if parent_id != null_id:
                ref parent = self[parent_id]
                self[child_id].next_sibling = parent.first_child
                parent.first_child = child_id
            return child_id

    fn free_node(mut self, parent: NodeId):
        var id = self.nodes[parent].first_child
        while True:
            if id == null_id:
                break
            else:
                self.free_node(id)
                id = self.nodes[id].next_sibling
        self.nodes[id].score = Score()
        self.nodes[id].next_sibling = self.free
        self.free = id

    fn reset(mut self):
        self.free_node(root_id)
        self.leaves.clear()
        self.leaves.append(NodeIdScore(root_id, Score.loss()))
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
    var score: Score
    var parent: NodeId
    var first_child: NodeId
    var next_sibling: NodeId

    fn __init__(out self, move: Self.Move, score: Score, /, parent_id: NodeId):
        self.move = move
        self.score = score
        self.parent = parent_id
        self.first_child = null_id
        self.next_sibling = null_id


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


from connect6 import Connect6

alias Game = Connect6[size=19, max_moves=8, max_places=6, max_plies=100]


fn main():
    var tree = Tree[Game, 20]()
    ref node = tree[0]
    node.parent = 123
    print(node.parent)
