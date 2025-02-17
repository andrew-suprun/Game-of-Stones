trait Game(ExplicitlyCopyable):
    alias Move: EqualityComparableCollectionElement

    fn top_moves(self, mut moves: List[Self.Move], mut values: List[Float32]):
        ...

    fn play_move(mut self, move: Self.Move):
        ...
