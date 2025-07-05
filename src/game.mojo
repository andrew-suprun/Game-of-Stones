alias Decision = Int
alias win: Decision = 1
alias loss: Decision = -1
alias draw: Decision = 0
alias undecided: Decision = 2

trait TGame(Copyable, Defaultable, Writable):
    alias Move: TMove

    fn moves(self) -> List[Move]:
        ...

    fn play_move(mut self, move: Move):
        ...

    fn rollout(self, move: Move) -> Decision:
        ...
        
    fn decision(self) -> Decision:
        ...

trait TMove(Copyable, Movable, Defaultable, Stringable, Representable, Writable):
    fn __init__(out self, text: String) raises:
        ...

    fn decision(self) -> Decision:
        ...
