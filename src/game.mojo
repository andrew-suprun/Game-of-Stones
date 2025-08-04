alias Score = Float32
alias Terminal = Bool

alias Decision = Int
alias undecided: Decision = 0
alias first_wins: Decision = 1
alias second_wins: Decision = 2
alias draw: Decision = 3

trait TGame(Copyable, Defaultable, Stringable, Writable):
    alias Move: TMove

    fn moves(self, max_moves: Int) -> List[(Move, Score, Terminal)]:
        ...

    fn play_move(mut self, move: Move):
        ...

    fn decision(self) -> Decision:
        ...

    fn hash(self) -> Int:
        ...

trait TMove(Copyable, Movable, EqualityComparable, Hashable, Defaultable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...
