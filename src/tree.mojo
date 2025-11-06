from game import TGame, Score, MoveScore


trait TTree:
    alias Game: TGame

    fn __init__(out self):
        ...

    fn search(mut self, game: Self.Game, max_time_ms: UInt) -> MoveScore[Self.Game.Move]:
        ...
