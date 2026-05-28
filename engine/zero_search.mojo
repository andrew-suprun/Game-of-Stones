from .traits import TTree, TGame


struct ZeroSearch[G: TGame](TTree):
    comptime Game = Self.G

    def __init__(out self):
        pass

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[MoveScore[Self.G.Move]]:
        var mv = game.top_moves()
        sort[Self.gt](mv)
        return [mv[0]]

    @staticmethod
    @parameter
    def gt(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score
