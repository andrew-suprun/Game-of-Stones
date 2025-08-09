alias Score = Float32
alias Terminal = Bool

alias Decision = Int
alias undecided: Decision = 0
alias first_wins: Decision = 1
alias second_wins: Decision = 2
alias draw: Decision = 3

trait TGame(Copyable, Defaultable, Stringable, Writable):
    alias Move: TMove

    fn moves(self, max_moves: Int) -> List[MoveScore[Move]]:
        ...

    fn play_move(mut self, move: Move):
        ...

    fn decision(self) -> Decision:
        ...

    fn hash(self) -> Int:
        ...

trait TMove(Copyable, Movable, Hashable, Defaultable, Stringable, Writable):
    fn __init__(out self, text: StringSlice) raises:
        ...

@fieldwise_init
struct MoveScore[Move: TMove](Copyable, Movable, Writable):
    var move: Move
    var score: Score
    var terminal: Bool

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.move)
        if self.terminal:
            if self.score > 0:
                writer.write(" win")
            elif self.score < 0:
                writer.write(" loss")
            else:
                writer.write(" draw")
        else:
            writer.write(self.score)


