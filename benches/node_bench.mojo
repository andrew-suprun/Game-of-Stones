from benchmark import benchmark, Unit


@register_passable("trivial")
struct Node:
    var move: Int32
    var score: Int32
    var first_child: Int32
    var next_sibling: Int32

    fn __init__(out self):
        self.move = 0
        self.score = 0
        self.first_child = 0
        self.next_sibling = 0


comptime len = 1_000_000_000


fn bench_index():
    var nodes = List[Node]()
    nodes.resize(unsafe_uninit_length=len)
    for i in range(len):
        nodes[i].move = i
        nodes[i].score = i
        nodes[i].first_child = i
        nodes[i].next_sibling = i


fn bench_ref():
    var nodes = List[Node]()
    nodes.resize(unsafe_uninit_length=len)
    for i in range(len):
        ref node = nodes[i]
        node.move = i
        node.score = i
        node.first_child = i
        node.next_sibling = i


fn main() raises:
    var report = benchmark.run[bench_index](0, 1, 3, 6)
    report.print()
    report = benchmark.run[bench_ref](0, 1, 3, 6)
    report.print()
