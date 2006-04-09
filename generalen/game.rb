# -*- coding: iso-8859-1 -*-
#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++

require 'forwardable'
require 'observer'
require 'set'
require 'util/orderedhash'
require 'util/swedish'
require 'generalen/setting'
require 'generalen/state'

class String
  def capitalize0
    self[0..0].upcase + self[1..-1]
  end
end

class Symbol
  def <=>(other)
    to_s <=> other.to_s
  end
end

module Game
  class FullGameException < RequestException; end
  class AlreadyJoinedException < RequestException; end
  class NotJoinedException < RequestException; end
  class AlreadyStartedException < RequestException; end
  class TooFewPlayersException < RequestException; end
  class NotInTurnException < RequestException; end
  class NotCountryOwnerException < RequestException; end
  class TooFewArmiesException < RequestException; end
  class TooManyArmiesException < RequestException; end
  class BorderingException < RequestException; end
  class CountryOwnerException < RequestException; end
  class TurnPhaseException < RequestException; end
  class TooManyCardsException < RequestException; end
  class MovesExhaustedException < RequestException; end
  class IllegalCardComboException < RequestException; end
  class InsuficcentCardsException < RequestException; end

  CARD_COMBOS = ([ [ { :a => 3, :b => 0, :c => 0, :* => 0 }, 4 ],
                   [ { :a => 2, :b => 0, :c => 0, :* => 1 }, 4 ],
                   [ { :a => 0, :b => 3, :c => 0, :* => 0 }, 6 ],
                   [ { :a => 0, :b => 2, :c => 0, :* => 1 }, 6 ],
                   [ { :a => 0, :b => 0, :c => 3, :* => 0 }, 8 ],
                   [ { :a => 0, :b => 0, :c => 2, :* => 1 }, 8 ],
                   [ { :a => 1, :b => 1, :c => 1, :* => 0 }, 10 ],
                   [ { :a => 1, :b => 1, :c => 0, :* => 1 }, 10 ],
                   [ { :a => 1, :b => 0, :c => 1, :* => 1 }, 10 ],
                   [ { :a => 0, :b => 1, :c => 1, :* => 1 }, 10 ],
                   [ { :a => 1, :b => 0, :c => 0, :* => 2 }, 10 ],
                   [ { :a => 0, :b => 1, :c => 0, :* => 2 }, 10 ],
                   [ { :a => 0, :b => 0, :c => 1, :* => 2 }, 10 ],
                   [ { :a => 0, :b => 0, :c => 0, :* => 3 }, 10 ] ])
  class Game
    include Observable
    attr_reader :name, :map, :people_players, :settings, :turn_queue, :turn_phase, :turn_deadline, :initial_turn_order, :started, :round

    def initialize(name, random_source)
      @name = name
      @random = random_source
      @settings = OrderedHash.new([ [ :gametype, Setting::GameType.new ],
                                    [ :timeout, Setting::Timeout.new ] ])
      @map = Map.new(self)
      @people_players = OrderedHash.new
      @initial_turn_order = []
      @turn_queue = []
      @turn_phase = 0
      @turn_deadline = nil
      @started = false
      @ended = false
      @round = 0
    end

    def people
      @people_players.keys
    end

    def players
      @people_players.values
    end

    def request(params = {})
      result = nil
      catch :result do
        if ADMIN_REQUESTS.include?(params[:type]) and
            params[:person].administrator?
          result = send(params[:type], params)
          throw :result
        elsif PLAYER_REQUESTS.include?(params[:type])
          if people.include?(params[:person])
            result = send(params[:type],
                          params.merge(:player => @people_players[params[:person]]))
            throw :result
          else
            raise NotJoinedException.new
          end
        else
          if PERSON_REQUESTS.include?(params[:type])
            result = send(params[:type], params)
            throw :result
          end
        end
        raise ArgumentError.new
      end
      people.each{ |p| p.flush }
      return result
    end

    ADMIN_REQUESTS = ([ :timeout_poll, :set_turn_queue ])
    PLAYER_REQUESTS = ([ :leave, :set, :ready, :surrender, :say, :place, :done, :attack, :move, :cards ])
    PERSON_REQUESTS = ([ :join ])

    def open
      not (@started or @ended)
    end
    def finished
      @ended and @started
    end
    def active
      not @ended
    end
    def first_placement
      @started and not first_placement_done
    end
    def first_placement_done
      @round > 0
    end
    def ongoing
      first_placement_done and active
    end
    def in_turn(person)
      if not @started or @ended
        false
      elsif first_placement
        not @people_players[person].first_placement_done
      else
        @turn_queue.first != :new_round and @turn_queue.first.person == person
      end
    end
    def active_players
      @turn_queue.reject{ |p| p == :new_round }
    end

    private
    def timeout_poll(params = {})
      if @turn_deadline and @turn_deadline < Time.now + 10
        changed
        notify_observers(:turn_timeout)
        make_placements_permanent
        advance_turn
        return true
      else
        return false
      end
    end

    def set_turn_queue(params = {})
      make_placements_permanent
      reset_moved_armies
      @round = 1 if @round == 0
      @turn_queue = params[:names].collect do |name|
        players.select{ |p| p.person.name == name.to_s }.first
      end
      @turn_queue << :new_round
      @turn_queue.first.armies_for_movement = 7
      players.each do |p|
        p.armies_for_placement = 0
      end
      if params[:armies_for_placement]
        @turn_queue.first.armies_for_placement = params[:armies_for_placement]
      end
    end

    def leave(params = {})
      if @started
        raise AlreadyStartedException.new
      end
      @people_players.delete(params[:person])
      changed
      notify_observers(:leave, :person => params[:person])
      if @people_players.empty?
        changed
        notify_observers(:ceased)
        @ended = true
      end
    end

    def set(params = {})
      if @started
        raise AlreadyStartedException.new
      elsif not params[:game].settings.values.include?(params[:setting])
        raise ArgumentError.new
      else
        params[:setting].set(params[:value])
        set_nobody_ready
        changed
        notify_observers(:set, :setting => params[:setting], :by_person => params[:person])
      end
    end

    def set_nobody_ready
      players.each do |player|
        player.ready = false
      end
      changed
      notify_observers(:nobody_ready)
    end

    def ready(params = {})
      if @started
        raise AlreadyStartedException.new
      elsif @people_players.length == 1
        raise TooFewPlayersException.new
      elsif @settings[:gametype].value == :mission and @people_players.length < 3
        raise TooFewPlayersException.new
      end
      @people_players[params[:person]].ready = true
      ready, not_ready = players.partition{ |p| p.ready }
      changed
      notify_observers(:ready, :person => params[:person], :not_ready => not_ready)
      if not_ready.empty?
        start_game
      end
    end

    def join(params = {})
      if @people_players.length == @map.max_players
        raise FullGameException.new
      end
      if people.include?(params[:person])
        raise AlreadyJoinedException.new
      end
      player = Player.new(self, params[:person])
      @people_players[params[:person]] = player
      set_nobody_ready
      changed
      notify_observers(:join, :person => params[:person])
    end

    def surrender(params = {})
      advance_turn_afterwards = (@turn_queue.first == params[:player])
      @turn_queue.delete(params[:player])
      changed
      notify_observers(:surrender, :person => params[:person])
      maybe_end_game
      unless @ended
        advance_turn if advance_turn_afterwards
      end
    end

    def say(params = {})
      changed
      notify_observers(:say, :person => params[:person], :text => params[:text])
    end

    def place(params = {})
      if not first_placement_done
        if params[:player].first_placement_done
          raise NotInTurnException.new
        end
      else
        if @turn_queue.first != params[:player]
          raise NotInTurnException.new
        else
          advance_turn_phase(0)
        end
      end
      max_armies = first_placement_done ? nil : 4
      placements = []
      exceptions = []
      params[:placement].each do |country, armies|
        if country.owner != params[:player]
          exceptions << NotCountryOwnerException.new(:country => country)
        elsif country.placed_armies + armies < 0
          exceptions << TooFewArmiesException.new(:country => country)
        elsif max_armies and country.armies + country.placed_armies + armies > max_armies
          exceptions << TooManyArmiesException.new(:country => country)
        elsif armies != 0
          country.placed_armies += armies
          placements << [country, armies]
          params[:player].armies_for_placement -= armies
        end
      end
      if params[:player].mission and params[:player].mission.params[:min_armies_per_country] > 1
        maybe_end_game
      end
      return [placements, exceptions]
    end

    def done(params = {})
      if not first_placement_done
        if params[:player].first_placement_done
          raise NotInTurnException.new
        else
          params[:player].first_placement_done = true
          done, not_done = players.partition{ |p| p.first_placement_done }
          changed
          notify_observers(:done, :person => params[:person], :not_done => not_done)
          if players.all?{ |p| p.first_placement_done }
            make_placements_permanent
            advance_turn
          end
        end
      else
        if @turn_queue.first != params[:player]
          raise NotInTurnException.new
        else
          advance_turn_phase(3)
          advance_turn
        end
      end
    end

    def attack(params = {})
      if @turn_queue.first != params[:player]
        raise NotInTurnException.new
      else
        advance_turn_phase(1)
        if params[:target].owner == params[:player]
          raise CountryOwnerException.new(:country => params[:target])
        elsif params[:from].owner != params[:player]
          raise NotCountryOwnerException.new(:country => params[:from])
        elsif params[:armies] < 1
          raise TooFewArmiesException.new
        elsif params[:armies] > params[:from].armies - 1
          raise TooManyArmiesException.new
        elsif not params[:target].borders.include?(params[:from])
          raise BorderingException.new
        else
          begin
            attacker_losses = 0
            defender_losses = 0
            attack_dice = [params[:armies], 3].min
            defence_dice = [params[:target].armies, 2].min
            attack = (1..attack_dice).collect{ @random.randrange(1..6) }.sort.reverse
            defence = (1..defence_dice).collect{ @random.randrange(1..6) }.sort.reverse
            attack.zip(defence).each do |a, d|
              if a and d
                if a > d
                  defender_losses += 1
                else
                  attacker_losses += 1
                end
              end
            end
            params[:from].armies -= attacker_losses
            params[:armies] -= attacker_losses
            params[:target].armies -= defender_losses
            changed
            notify_observers(:attack, params.merge(:attack => attack,
                                                   :defence => defence,
                                                   :attacker_losses => attacker_losses,
                                                   :defender_losses => defender_losses))
            break if params[:armies] < 3 or params[:target].armies == 0
          end while params[:destroy]
          if params[:target].armies == 0
            loser = params[:target].owner
            params[:target].owner = params[:player]
            params[:target].armies = params[:armies]
            params[:from].armies -= params[:armies]
            params[:player].card_earned = true
            changed
            notify_observers(:conquer, params)
            if loser && loser.countries.empty?
              params[:player].has_defeated << loser
              @turn_queue.delete(loser)
              changed
              notify_observers(:defeated, :person => loser, :by_person => params[:person], :cards => loser.cards, :n_cards => loser.total_cards)
              loser.cards.keys.each do |c|
                params[:player].cards[c] += loser.cards[c]
                loser.cards[c] = 0
              end
            end
            maybe_end_game
          end
        end
      end
      return params[:armies]
    end

    def move(params = {})
      if @turn_queue.first != params[:player]
        raise NotInTurnException.new
      else
        advance_turn_phase(2)
        if params[:to].owner != params[:player]
          raise NotCountryOwnerException.new(:country => params[:to])
        elsif params[:from].owner != params[:player]
          raise NotCountryOwnerException.new(:country => params[:from])
        elsif params[:armies] < 1
          raise TooFewArmiesException.new
        elsif params[:armies] > params[:from].movable_armies
          raise TooManyArmiesException.new
        elsif params[:armies] > params[:player].armies_for_movement
          raise MovesExhaustedException.new
        elsif not params[:to].borders.include?(params[:from])
          raise BorderingException.new
        else
          params[:from].armies -= params[:armies]
          params[:to].armies += params[:armies]
          params[:to].moved_armies += params[:armies]
          params[:player].armies_for_movement -= params[:armies]
          changed
          notify_observers(:move, params)
          if params[:player].mission and params[:player].mission.params[:min_armies_per_country] > 1
            maybe_end_game
          end
          if params[:player].armies_for_movement == 0
            advance_turn
          end
        end
      end
    end

    def cards(params = {})
      if @turn_queue.first != params[:player]
        raise NotInTurnException.new
      else
        advance_turn_phase(0)
        if not CARD_COMBOS.assoc(params[:cards])
          raise IllegalCardComboException.new
        elsif params[:cards].sort.zip(@turn_queue.first.cards.sort).any?{ |c, p| c.last > p.last }
          raise InsuficcentCardsException.new
        else
          bonus_armies = CARD_COMBOS.assoc(params[:cards]).last
          params[:cards].each do |card, n|
            params[:player].cards[card] -= n
          end
          @turn_queue.first.armies_for_placement += bonus_armies
          changed
          notify_observers(:cards, params.merge(:armies => bonus_armies))
        end
      end
    end

    def start_game
      @turn_queue = @random.shuffle(players)
      @initial_turn_order = @turn_queue.clone
      @started = true
      if @settings[:gametype].value == :mission
        missions = (0...@map.n_missions(@people_players.length)).collect
        players.each do |p|
          mission = @random.choose_n_from(1, missions).first
          missions.delete(mission)
          p.mission = @map.mission(p, mission, players)
        end
      end
      players.each_with_index do |p, i|
        p.number = i
        p.armies_for_placement = @map.starting_armies(players.length)
      end
      countries = @map.countries.clone
      catch :countries_empty do
        assign_queue = @turn_queue.clone
        assign_queue.unshift(nil) if @turn_queue.length < 3
        loop do
          assign_queue.reverse.each do |player|
            country = @random.choose_n_from(1, countries).first
            countries.delete(country)
            country.owner = player
            country.armies = (if player then 1 else 2 end)
            player.armies_for_placement -= 1 if player
            throw :countries_empty if countries.empty?
          end
        end
      end
      @turn_queue.unshift(:new_round)
      changed
      notify_observers(:started)
      maybe_set_deadline
    end

    def end_game
      @ended = true
      changed
      notify_observers(:ceased)
    end

    def maybe_end_game
      if first_placement_done and @turn_queue.first != :new_round and @turn_queue.first.mission and @turn_queue.first.mission.completed?
        changed
        @turn_queue.first.winner = true
        notify_observers(:winner, :person => @turn_queue.first.person)
        end_game
      elsif active_players.length == 1
        changed
        active_players.first.winner = true
        notify_observers(:winner, :person => active_players.first.person)
        end_game
      end
    end

    def make_placements_permanent
      placements = {}
      @map.countries.each do |c|
        if c.owner && c.owner.armies_for_placement >= 0
          c.armies += c.placed_armies
          placements[c] = c.placed_armies if c.placed_armies > 0
        end
        c.placed_armies = 0
      end
      if first_placement_done
        changed
        notify_observers(:place, :person => @turn_queue.first.person, :placements => placements)
      end
    end

    def reset_moved_armies
      @map.countries.each do |c|
        c.moved_armies = 0
      end
    end

    def maybe_set_deadline
      if settings[:timeout].value > 0
        @turn_deadline = Time.now + 60 * settings[:timeout].value
      end
    end

    def previous_player
      if @turn_queue.last == :new_round
        @turn_queue[-2]
      else
        @turn_queue.last
      end
    end

    def advance_turn
      if @turn_queue.first == :new_round
        @round += 1
      else
        reset_moved_armies
        if @turn_queue.first.card_earned
          @turn_queue.first.card_earned = false
          @turn_queue.first.recieve_card(case @random.randrange(0...44)
                                         when 0..13: :a
                                         when 14..27: :b
                                         when 28..41: :c
                                         when 42..43: :*
                                         end)
          changed
          notify_observers(:card, :to_player => @turn_queue.first)
        end
      end
      @turn_queue.push(@turn_queue.shift)
      if @turn_queue.first == :new_round
        advance_turn
      else
        maybe_set_deadline
        @turn_phase = 0
        @turn_queue.first.armies_for_placement = (if @round > 1
                                                    @turn_queue.first.bonus_armies
                                                  else
                                                    0
                                                  end)
        @turn_queue.first.armies_for_movement = 7
        changed
        notify_observers(:turn_change, :to_person => @turn_queue.first.person, :from_person => previous_player.person)
      end
    end

    def advance_turn_phase(to_phase)
      if @turn_phase > to_phase or (to_phase > 0 and @turn_queue.first.armies_for_placement != 0)
        raise TurnPhaseException.new(:from => @turn_phase, :to => to_phase)
      elsif @turn_queue.first.total_cards >= 5 and to_phase > 0
        raise TooManyCardsException.new
      else
        @turn_phase = to_phase
        if to_phase > 0
          make_placements_permanent
        end
      end
    end
  end


  class Player
    extend Forwardable
    def_delegator :@person, :post
    def_delegator :@person, :name

    attr_reader :game, :person
    attr_accessor :number, :ready, :mission, :armies_for_placement, :armies_for_movement, :first_placement_done
    attr_accessor :cards, :card_earned, :last_card, :has_defeated, :surrendered, :winner, :loser

    def initialize(game, person)
      @game = game
      @person = person
      @number = nil
      @ready = false
      @mission = nil
      @armies_for_placement = 0
      @armies_for_movement = 0
      @first_placement_done = false
      @card_earned = false
      @cards = { :a => 0, :b => 0, :c => 0, :* => 0 }
      @last_card = nil
      @has_defeated = []
      @surrendered = false
      @winner = false
      @loser = false
    end
    def countries
      @game.map.countries.select{ |c| c.owner == self }
    end
    def bonus_armies
      armies = [countries.length / 3, 3].max
      continents.each do |c|
        armies += c.bonus_armies
      end
      return armies
    end
    def total_cards
      @cards.values.inject(0){ |a, b| a+b }
    end
    def armies
      countries.inject(0){ |acc, c| acc + c.armies }
    end
    def attackable_countries
      result = Set.new
      countries.select{ |c| c.total_armies > 1 }.each do |c|
        c.borders.each do |b|
          if b.owner != self
            result.add(b)
          end
        end
      end
      return result
    end
    def recieve_card(card)
      @cards[card] += 1
      @last_card = card
    end
    def continents
      @game.map.continents.select do |c|
        c.countries.all?{ |c| countries.include?(c) }
      end
    end
  end

  class Map
    attr_reader :game, :name, :countries, :continents

    NAME = :standard

    COUNTRY_NAMES = ['Grönland', 'Alaska', 'Jakutsk', 'Kamchatka',
      'Nordvästra territoriet', 'Island', 'Skandinavien', 'Ontario',
      'Quebec', 'Ural', 'Irkutsk', 'Alberta', 'Storbritannien',
      'Ukraina', 'Sibirien', 'Östra Förenta Staterna', 'Mongoliet',
      'Västra Förenta Staterna', 'Nordeuropa', 'Japan', 'Västeuropa',
      'Afghanistan', 'Sydeuropa', 'Kina', 'Centralamerika',
      'Mellanöstern', 'Nordafrika', 'Egypten', 'Indien', 'Siam',
      'Venezuela', 'Peru', 'Brasilien', 'Östafrika', 'Kongo',
      'Indonesien', 'Nya Guinea', 'Madagaskar', 'Argentina',
      'Sydafrika', 'Västra Australien', 'Östra Australien']

    COUNTRY_BORDERING = [[4,5,7,8], [3,4,11], [3,10,14], [1,2,10,16,19],
      [0,1,7,11], [0,6,12], [5,12,13,18], [0,4,11,8,15,17], [0,7,15],
      [13,14,21,23], [2,3,14,16], [1,4,7,17], [5,6,18,20],
      [6,9,18,21,22,25], [2,9,10,16,23], [7,8,17,24], [3,10,14,19,23],
      [7,11,15,24], [6,12,13,20,22], [3,16], [12,18,22,26],
      [9,13,23,25,28], [13,18,20,25,26,27], [9,14,16,21,28,29], [15,17,30],
      [13,21,22,27,28], [20,22,27,32,33,34], [22,25,26,33],
      [21,23,25,29], [23,28,35], [24,31,32], [30,32,38], [26,30,31,38],
      [26,27,34,37,39], [26,33,39], [29,36,40], [35,40,41], [33,39],
      [31,32], [33,34,37], [35,36,41], [36,40]]

    CONTINENTS = ([ ['Nordamerika', [0,1,4,7,8,11,15,17,24], 5],
                    ['Europa', [5,6,12,13,18,20,22], 5],
                    ['Asien', [2,3,9,10,14,16,19,21,23,25,28,29], 7],
                    ['Sydamerika', [30,31,32,38], 2],
                    ['Afrika', [26,27,33,34,37,39], 3],
                    ['Australien', [35,36,40,41], 2] ])

    MAX_PLAYERS = 6

    STARTING_ARMIES = {2 => 40, 3 => 35, 4 => 30, 5 => 25, 6 => 20}

    MISSIONS = ([ {:continents => [2, 3], :n_continents => 2},
                  {:continents => [2, 4], :n_continents => 2},
                  {:continents => [0, 4], :n_continents => 2},
                  {:continents => [0, 5], :n_continents => 2},
                  {:continents => [1, 3], :n_continents => 3},
                  {:continents => [1, 5], :n_continents => 3},
                  {:n_countries => 18, :min_armies_per_country => 2},
                  {:n_countries => 24} ])

    FALLBACK_MISSION = { :n_countries => 24 }

    def initialize(game)
      @game = game
      @name = NAME
      @countries = COUNTRY_NAMES.collect { |n| Country.new(self, n) }
      @countries.zip(COUNTRY_BORDERING).each do |c, borders|
        borders.each do |b|
          c.borders << @countries[b]
        end
      end
      @continents = CONTINENTS.collect do |name, countries, bonus_armies|
        c = countries.collect { |country| @countries[country] }
        continent = Continent.new(name, c, bonus_armies)
        c.each do |country|
          country.continent = continent
        end
        continent
      end
    end

    def max_players
      MAX_PLAYERS
    end
    def n_missions(n_players)
      MISSIONS.length + n_players
    end
    def mission(player, n, players)
      if n < MISSIONS.length
        return Mission.new(player, MISSIONS[n], nil)
      else
        return Mission.new(player, { :kill_player => players[n - MISSIONS.length] }, FALLBACK_MISSION)
      end
    end
    def starting_armies(n_players)
      STARTING_ARMIES[n_players]
    end
  end

  class Country
    attr_accessor :name, :owner, :armies, :placed_armies, :moved_armies, :continent, :borders
    def initialize(map, name)
      @map = map
      @name = name
      @owner = nil
      @armies = 0
      @placed_armies = 0
      @moved_armies = 0
      @continent = nil
      @borders = []
    end
    def total_armies
      @armies + @placed_armies
    end
    def movable_armies
      @armies - [@moved_armies, 1].max
    end
    def <=>(other)
      @name <=> other.name
    end
  end

  class Continent
    attr_reader :name, :countries, :bonus_armies
    def initialize(name, countries, bonus_armies)
      @name = name
      @countries = countries
      @bonus_armies = bonus_armies
    end
  end

  class Mission
    attr_reader :params
    KEYS = [ :kill_player, :continents, :n_continents, :n_countries, :min_armies_per_country ]
    def initialize(player, params, fallback_params)
      if params.keys.any?{ |k| not KEYS.include?(k) }
        raise ArgumentError.new
      end
      @player = player
      @params = params.clone
      @fallback_params = fallback_params
      [ @params, @fallback_params ].compact.each do |p|
        p[:continents] ||= []
        p[:n_countries] ||= 0
        p[:n_continents] ||= 0
        p[:min_armies_per_country] ||= 1
        p[:continents] = p[:continents].collect{ |c| @player.game.map.continents[c] }
      end
    end

    def completed?(params = nil)
      params ||= @params
      if params[:kill_player]
        if not @player.game.active_players.include?(params[:kill_player])
          if not @player.has_defeated.include?(params[:kill_player])
            return completed?(@fallback_params)
          end
        else
          return false
        end
      end
      if not params[:continents].empty?
        if not params[:continents].collect.to_set.subset?(@player.continents.to_set)
          return false
        end
      end
      if params[:n_continents] > 0
        if @player.continents.length < params[:n_continents]
          return false
        end
      end
      if params[:n_countries] > 0
        if @player.countries.length < params[:n_countries]
          return false
        end
      end
      if params[:min_armies_per_country] > 1
        if @player.armies_for_placement < 0
          return false
        elsif @player.countries.select{ |c| c.total_armies >= params[:min_armies_per_country] }.length < params[:n_countries]
          return false
        end
      end
      return true
    end

    def swedish(params = nil)
      params ||= @params
      result = []
      if params[:kill_player]
        result << 'utplåna %s' % params[:kill_player].name
      end
      if not params[:continents].empty?
        continents = 'erövra %s' % params[:continents].names.swedish
        if params[:n_continents] > params[:continents].length
          continents << ', samt ytterligare %s' % (params[:n_continents] - params[:continents].length).swedish_quantity('valfri kontinent', 'valfria kontinenter')
        end
        result << continents
      elsif params[:n_continents] > 0
        result << 'erövra %s' % (params[:n_continents] - params[:continents].length).swedish_quantity('valfri kontinent', 'valfria kontinenter')
      end
      if params[:n_countries] > 0
        result << 'erövra %d valfria länder' % params[:n_countries]
      end
      if params[:min_armies_per_country] > 1
        result << 'placera minst %d arméer i varje land' % params[:min_armies_per_country]
      end
      result = result.swedish.capitalize0 + '.'
      if params[:kill_player]
        result << ' Om du är %s, eller om någon annan utplånar %s, %s' % ([ params[:kill_player].name,
                                                                              params[:kill_player].name,
                                                                              swedish(@fallback_params).downcase ])
      end
      return result
    end
  end
end
