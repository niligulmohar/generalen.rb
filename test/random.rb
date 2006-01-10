require 'test/unit'
require 'util/random'

class SourceTestCase < Test::Unit::TestCase
  def test_distribution
    # TODO
  end
end

class TestSourceTestCase < Test::Unit::TestCase
  def test_range
    source = Random::TestSource.new
    source.randrange_results.push(5, 0, 6)

    assert_equal(5, source.randrange((1..5)))
    assert_raise(Random::TestSourceMismatch) { source.randrange((1..5)) }
    assert_raise(Random::TestSourceMismatch) { source.randrange((1..5)) }
    assert_raise(Random::TestSourceExhausted) { source.randrange((1..5)) }
  end

  def test_choose
    array = [:foo, :bar]
    source = Random::TestSource.new
    source.choose_results.push([0], [1, 0], [0], [2])

    assert_equal([:foo], source.choose_n_from(1, array))
    assert_equal([:bar, :foo], source.choose_n_from(2, array))
    assert_raise(Random::TestSourceMismatch) { source.choose_n_from(2, array) }
    assert_raise(IndexError) { source.choose_n_from(1, array) }
    assert_raise(Random::TestSourceExhausted) { source.choose_n_from(1, array) }
  end
end
