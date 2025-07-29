alias Score = Float32
alias Decision = Int8

alias undecided: Decision = 0
alias win: Decision = 1
alias draw: Decision = 2
alias loss: Decision = 3

trait TGame(Defaultable, Stringable, Writable):
    alias Move: TMove

    fn moves(self) -> List[Move]:
        ...

    fn best_score(self) -> Score:
        ...

    fn play_move(mut self, move: Move):
        ...

    fn undo_move(mut self, move: Move):
        ...

    fn decision(self) -> Decision:
        ...

trait TMove(Copyable, Movable, Defaultable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...
    fn score(self) -> Score:
        ...

    fn set_score(mut self, score: Score):
        ...

    fn decision(self) -> Decision:
        ...

    fn set_decision(mut self, decision: Decision):
        ...

trait TScore(Copyable, Movable, Comparable, Defaultable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...
