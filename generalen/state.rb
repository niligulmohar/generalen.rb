# coding: utf-8
#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++
require 'pstore'
require 'thread'

class RequestException < Exception
  attr_reader :params
  def initialize(params = {})
    @params = params
  end
end
class TooManyGamesException < RequestException; end

require_relative '../generalen/game'

class State
  attr_reader :store
  def initialize(filename, random_source)
    @mutex = Mutex.new
    @store = PStore.new(filename)
    @store.transaction do
      unless @store[:inited]
        @store[:people] = ({ :admin => Person::Administrator.new,
                             :Test => Person::TestPerson.new('Test'),
                             :Ap => Person::TestPerson.new('Ap') })
        @store[:games] = []
        @store[:last_game_number] = 0
        @store[:inited] = true
        @store[:random] = random_source
      end
    end
  end

  def transaction()
    @mutex.synchronize do
      @store.transaction do
        @store[:mtime] = Time.now
        yield
      end
    end
  end

  def register_person(key, klass, *params)
    transaction do
      if @store[:people].has_key?(key)
        if not @store[:people][key].instance_of?(klass)
          raise TypeError('Person expected to be of different class')
        end
      end
      @store[:people][key] = klass.new(*params)
    end
  end

  def with_person(key)
    transaction do
      yield @store[:people][key]
    end
  end

  def with_random_source
    transaction do
      yield @store[:random]
    end
  end

  def open_games
    @store[:games].select{ |g| g.open }
  end

  def games
    @store[:games]
  end

  def running_games
    @store[:games].select{ |g| g.active and not g.open }
  end

  def finished_games
    @store[:games].select{ |g| g.finished }
  end

  def random
    @store[:random]
  end

  def startup
    transaction do
      if @store[:shutdown].nil?
        push_deadlines
      else
        push_deadlines
      end
      @store[:shutdown] = nil
    end
  end

  def shutdown
    transaction do
      @store[:shutdown] = Time.now
    end
  end

  def request(params = {})
    if not params.has_key?(:person)
      raise RuntimeError.new(':person-parameter missing in request')
    end
    if params[:person].administrator? and
        ADMIN_REQUESTS.include?(params[:type])
      return send(params[:type], params)
    elsif PERSON_REQUESTS.include?(params[:type])
      return send(params[:type], params)
    elsif GAME_REQUESTS.include?(params[:type]) and params.has_key?(:game)
      return params[:game].request(params)
    else
      raise ArgumentError.new
    end
  end

  ADMIN_REQUESTS = ([ :stop, :start, :push_deadlines ])
  PERSON_REQUESTS = ([ :new_game ])
  GAME_REQUESTS = Game::Game::ADMIN_REQUESTS + Game::Game::PLAYER_REQUESTS + Game::Game::PERSON_REQUESTS

  private
  def stop
  end

  def start
  end

  def push_deadlines(params = {})
    $logger.info "Pushing deadlines"
    @store[:games].each do |g|
      g.push_deadline
    end
  end

  def new_game(params = {})
    games = @store[:games].select{ |g| g.active and g.people.include?(params[:person]) }
    if games.length > 17
      raise TooManyGamesException.new
    end
    @store[:last_game_number] += 1
    if params[:name].empty?
      name = @store[:last_game_number].swedish(:ordinal => true).capitalize + ' partiet'
    else
      name = params[:name]
    end
    game = Game::Game.new(name, random)
    @store[:games] << game
    return game
  end
end
