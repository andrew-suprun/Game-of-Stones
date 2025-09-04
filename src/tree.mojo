from game import TGame, Score, MoveScore


trait TTree:
    alias Game: TGame

    fn __init__(out self):
        ...

    fn search(mut self, mut game: Game, max_time_ms: Int) -> MoveScore[Game.Move]:
        ...
