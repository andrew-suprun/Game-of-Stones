from testing import assert_true, assert_false

from score import Score


def test_compare_scores():
    var w = Score.win()
    var l = Score.loss()
    var d = Score.draw()

    assert_true(w >= w)
    assert_true(d >= d)
    assert_true(l >= l)
    assert_true(w <= w)
    assert_true(d <= d)
    assert_true(l <= l)
    assert_true(w == Score.win())
    assert_true(l == Score.loss())
    assert_true(d == Score.draw())
    assert_true(w > d)
    assert_true(d > l)
    assert_true(d < w)
    assert_true(l < d)
    assert_false(d == Score())
    assert_true(d != Score())
    assert_true(d < Score(1))
    assert_true(w > Score(1))
    assert_true(d > Score(-1))
    assert_true(l < Score(-1))
    assert_true(d == -d)
    var zero = Score(0.0)
    assert_true(zero == -zero)
