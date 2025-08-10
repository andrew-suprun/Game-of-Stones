from game import TGame, Score, Decision

trait TTree:
    alias Game: TGame

    fn __init__(out self):
        ...

    fn search(mut self, game: Game, max_time_ms: Int) -> (Score, List[Game.Move]):
        ...