pub const Player = enum { first, second };
pub const Decision = enum {
    no_decision,
    first_win,
    second_win,
    draw,

    pub fn str(self: Decision) []const u8 {
        return switch (self) {
            .no_decision => "no-decision",
            .first_win => "first-win",
            .second_win => "second-win",
            .draw => "draw",
        };
    }
};
