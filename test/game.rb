require 'test/unit'
require 'generalen/game'

class MapTestCase < Test::Unit::TestCase
  def setup
    @map = Game::Map.new(nil)
  end
  def test_bordering_reflexiveness
    @map.countries.each do |c|
      c.borders.each do |b|
        assert(b.borders.include?(c))
      end
    end
  end
end
