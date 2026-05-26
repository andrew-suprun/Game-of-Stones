from .traits import TTree, TGame


struct ZeroSearch[G: TGame](TTree):
    comptime Game = Self.G

    def __init__(out self):
        pass

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        var mv = game.top_moves()
        sort[Self.gt](mv)
        return [mv[0].move]

    @staticmethod
    @parameter
    def gt(a: MoveValue[Self.G.Move], b: MoveValue[Self.G.Move]) -> Bool:
        return a.value > b.value
