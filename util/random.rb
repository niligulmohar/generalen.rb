
class Array
  def choose(n = 1)
    remaining = clone
    result = []
    n.times do
      i = remaining[(0...remaining.length).random]
      remaining.delete i
      result << i
    end
    result
  end
  def shuffle
    choose(length)
  end
end

class Range
  def random
    (rand * (last-first) + first).to_i
  end
end

module Random
  class Source
    def initialize
    end
    def randrange(range)
      range.random
    end
    def choose_n_from(n, array)
      array.choose(n)
    end
    def shuffle(array)
      choose_n_from(array.length, array)
    end
  end

  class TestSourceExhausted < RuntimeError; end
  class TestSourceMismatch < RuntimeError; end

  class TestSource < Source
    attr_reader :randrange_results, :choose_results
    def initialize
      @randrange_results = []
      @choose_results = []
      super
    end
    def randrange(range)
      raise TestSourceExhausted if @randrange_results.empty?
      result = @randrange_results.shift
      if not range.include? result
        raise TestSourceMismatch.new('randrange result out of range')
      end
      return result
    end
    def choose_n_from(n, array)
      raise TestSourceExhausted if @choose_results.empty?
      result = @choose_results.shift
      if not result.length == n
        raise TestSourceMismatch.new('n mismatch in choose_n_from')
      end
      result.each do |r|
        if not (0...array.length).include?(r)
          raise IndexError.new('choose result index out of range in choose_n_from')
        end
      end
      return result.map{ |n| array[n] }
    end
  end
end
