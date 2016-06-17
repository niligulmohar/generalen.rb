require 'minitest/autorun'
require_relative '../generalen/game'

class MapTestCase < Minitest::Test
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
