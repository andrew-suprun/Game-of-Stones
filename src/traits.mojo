comptime Score = Int32


trait TTree(ImplicitlyDestructible):
    comptime Game: TGame

    def __init__(out self):
        ...

    def search(mut self, game: Self.Game, max_time_ms: UInt) -> Self.Game.Move:
        ...


trait TGame(Copyable, Defaultable, Writable):
    comptime Move: TMove

    def moves(self) -> List[Self.Move]:
        ...

    def play_move(mut self, move: Self.Move):
        ...


trait TMove(Defaultable, Equatable, ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    def __init__(out self, text: String) raises:
        ...

    def score(self) -> Score:
        ...
        
    def set_score(mut self, score: Score):
        ...

    def is_terminal(self) -> Bool:
        ...
        
    def is_decisive(self) -> Bool:
        ...
        
    def set_decisive(mut self):
        ...

