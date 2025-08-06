from game import TGame, Score

trait TTree:
    alias Game: TGame

    fn __init__(out self, no_legal_moves_score: Score):
        ...

    fn search(mut self, game: Game, max_time_ms: Int) -> (Score, List[Game.Move]):
        ...