from score import Score


trait TGame(Defaultable, Stringable, Writable):
    alias Move: TMove

    fn moves(mut self) -> List[(Self.Move, Score)]:
        ...

    fn move(mut self) -> (Self.Move, Score):
        ...

    fn play_move(mut self, move: Self.Move):
        ...

    fn undo_move(mut self, move: Self.Move):
        ...

    fn hash(self) -> Int:
        ...


trait TMove(Defaultable, Hashable, ImplicitlyCopyable, Movable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...
