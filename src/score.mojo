comptime Score = Int32
comptime Win: Score = 5000
comptime Loss: Score = -Win
comptime Draw: Score = Score.MIN


def is_win(score: Score) -> Bool:
    return score >= Win


def is_loss(score: Score) -> Bool:
    return score <= Loss and score != Draw


def is_draw(score: Score) -> Bool:
    return score == Draw


def is_decisive(score: Score) -> Bool:
    return score <= Loss or score >= Win


def max_score(a: Score, b: Score) -> Score:
    var a_draw = is_draw(a)
    var b_draw = is_draw(b)
    if a_draw and b_draw:
        return Draw

    var aa = a if not a_draw else 0
    var bb = b if not b_draw else 0
    return aa if aa > bb else bb



def score_str(score: Score) -> String:
    if is_win(score):
        return "win"
    elif is_loss(score):
        return "loss"
    elif is_draw(score):
        return "draw"
    else:
        return String(score)
