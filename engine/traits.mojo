from .value import Value, value_str


trait TTree(ImplicitlyDestructible, Writable):
    comptime Game: TGame

    def __init__(out self):
        ...

    def search(mut self, game: Self.Game, max_time_ms: UInt, out pv: List[Self.Game.Move]):
        ...

    def value(self) -> Value:
        ...


trait TGame(Copyable, Defaultable, ImplicitlyDestructible, Writable):
    comptime Move: TMove

    def top_moves(self) -> List[MoveValue[Self.Move]]:
        ...

    def play_move(mut self, move: Self.Move):
        ...

    def value(self) -> Value:
        ...


trait TMove(Copyable, Defaultable, TrivialRegisterPassable, Writable):
    @implicit
    def __init__(out self, text: String) raises:
        ...


@fieldwise_init
struct MoveValue[Move: TMove](Copyable, ImplicitlyDestructible, Writable):
    var move: Self.Move
    var value: Value

    def write_to[W: Writer](self, mut writer: W):
        writer.write(t"{self.move} {value_str(self.value)}")

    # def write_repr_to[W: Writer](self, mut writer: W):
    #     writer.write(t"{self.move} {value_str(self.value)}")
