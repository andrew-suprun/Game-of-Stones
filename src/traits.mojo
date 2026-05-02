from score import Score


trait TTree(ImplicitlyDestructible, Writable):
    comptime Game: TGame

    def __init__(out self):
        ...

    def search(mut self, game: Self.Game, max_time_ms: UInt, out pv: List[Self.Game.Move]):
        ...


trait TGame(Copyable, Defaultable, ImplicitlyDestructible, Writable):
    comptime Move: TMove

    def moves(self) -> List[Self.Move]:
        ...

    def play_move(mut self, move: Self.Move):
        ...

    def score(mut self) -> Score:
        ...


trait TMove(Defaultable, Equatable, ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    def __init__(out self, text: String) raises:
        ...

    def score(self) -> Score:
        ...

    def set_score(mut self, score: Score):
        ...
