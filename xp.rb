
require 'mathn'

LEVEL_FACTOR = 10 # 300
CR_FACTOR = 1.1 # Math.sqrt(2)
MAX_CR_DIFF = 2 # 8

def xp(level, cr)
  (level * LEVEL_FACTOR) * CR_FACTOR ** [(cr - level), MAX_CR_DIFF].min
end

LEVEL_ONE_XP = 30 # 1000
def level_xp_floor(level)
  n = level -1
  n*(1+(n-1)/2) * LEVEL_ONE_XP
end

class Player
  attr_reader :xp, :level, :games, :wins
  def initialize(name)
    @name = name
    @xp = 0
    @level = 1
    @games = 0
    @wins = 0
  end
  def to_s
    "#@name (Lvl #@level, #@xp XP) #@wins/#@games wins"
  end
  def xp_up(xp)
    @xp += xp
    while @xp >= level_xp_floor(@level + 1)
      @level += 1
    end
  end
  def games_up
    @games += 1
  end
  def wins_up
    @wins += 1
  end
end

players = %w{ Pelle Kalle Olle Nisse Sixten Orvar Bosse Korven }.collect do |n|
  Player.new n
end

def pick(array, n)
  alts = array.clone
  picks = []
  n.times do
    alt = alts[(rand*alts.length).to_i]
    picks << alt
    alts.delete alt
  end
  picks
end

def play(players, n)
  g = pick(players, n)
  g.each{|p| p.games_up}
  puts g
  (n-3).times do
    loser = pick(g,1)[0]
    puts '--- loser: %s' % loser.to_s
    g.delete loser
  end
  (2).times do
    loser = pick(g,1)[0]
    puts '--- loser: %s' % loser.to_s
    g.delete loser
    avg_level = g.collect{|p| p.level}.inject(0){|a,b|a+b} / (1.0 * g.length)
    each_xp = (xp(avg_level, loser.level) / g.length).to_i
    puts '    each_xp: %d' % each_xp
    g.each{|p| p.xp_up(each_xp)}
    puts g
  end
  g[0].wins_up
  puts
end

20.times do
  play(players[1..-2], 6)
end
4.times do
  play(players, 6)
end

puts players
