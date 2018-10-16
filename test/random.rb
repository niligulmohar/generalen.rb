require 'minitest/autorun'
require_relative '../util/random'

class SourceTestCase < Minitest::Test
  def test_distribution
    # TODO
  end
end

class TestSourceTestCase < Minitest::Test
  def test_range
    source = Randomness::TestSource.new
    source.randrange_results.push(5, 0, 6)

    assert_equal(5, source.randrange((1..5)))
    assert_raises(Randomness::TestSourceMismatch) { source.randrange((1..5)) }
    assert_raises(Randomness::TestSourceMismatch) { source.randrange((1..5)) }
    assert_raises(Randomness::TestSourceExhausted) { source.randrange((1..5)) }
  end

  def test_choose
    array = [:foo, :bar]
    source = Randomness::TestSource.new
    source.choose_results.push([0], [1, 0], [0], [2])

    assert_equal([:foo], source.choose_n_from(1, array))
    assert_equal([:bar, :foo], source.choose_n_from(2, array))
    assert_raises(Randomness::TestSourceMismatch) { source.choose_n_from(2, array) }
    assert_raises(IndexError) { source.choose_n_from(1, array) }
    assert_raises(Randomness::TestSourceExhausted) { source.choose_n_from(1, array) }
  end
end
