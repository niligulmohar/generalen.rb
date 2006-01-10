require 'test/unit'
require 'util/orderedhash'

class OrderedHashTestCase < Test::Unit::TestCase
  def setup
    @keys = (1..500).collect { rand }
  end

  def test_order
    @oh = OrderedHash.new
    @keys.each { |k| @oh[k] = k }
    assert_order

    @oh.clear
    @keys.sort!
    @keys.each { |k| @oh[k] = k }
    assert_order
  end

  def test_init
    alist = @keys.collect{ |k| [k, k] }
    @oh = OrderedHash.new(alist)
    assert_order
  end

  private
  def assert_order
    assert(@oh.zip(@keys).all? do |pair, key|
             pair[0] == key
           end)
  end
end
