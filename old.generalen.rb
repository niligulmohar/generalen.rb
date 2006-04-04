#! /usr/bin/env ruby
# -*- coding: iso-8859-1 -*-

require 'logger'
require 'monitor'
require 'pp'
require 'pstore'
require 'readline'

require 'kom'
require 'prefix_words_matches'
require 'random'
require 'swedish'
require 'view'

######################################################################

class CommandError < RuntimeError; end

class AlternativesError < CommandError
  def initialize(alts, name = 'alternativ')
    if alts.empty?
      @alts = 'Din inmatning matchar inga %s!' % name
    else
      @alts = "Vilket av följande %s menar du?\n%s" % [ name,  alts.collect{ |a| a.first.join(' ') }.sort.column_list_view ]
    end
  end
  def message
    @alts
  end
end

######################################################################

module Enumerable
  def pick_from_with_rest(words, type = 'alternativ')
    pick_from(words, type, true)
  end

  def pick_from(words, type = 'alternativ', rest = false)
    hash = name_hash
    alts = hash.prefix_words_matches(words)
    if alts.length != 1
      raise AlternativesError.new(alts, type)
    end
    if rest
      [hash[alts[0].first], alts[0].last]
    else
      hash[alts[0].first]
    end
  end
end

######################################################################
#  ____
# |  _ \ ___ _ __ ___  ___  _ __
# | |_) / _ \ '__/ __|/ _ \| '_ \
# |  __/  __/ |  \__ \ (_) | | | |_ _ _
# |_|   \___|_|  |___/\___/|_| |_(_|_|_)

class Person
  attr_reader :messages
  def initialize(id)
    @id = id
    @messages = []
    @games = []
    @current_game = nil
  end
  def all_messages
    @messages.collect{|m|m.strip}.join "\n\n"
  end
  def name
    if @id == :admin
      'Generalsstaben'
    else
      $kombot.conf_name(@id)
    end
  end
  def long_name
    if @id == :admin
      name
    else
      '<person %p: %s>' % [@id, name]
    end
  end

  ##################################################

  def post(message)
    @messages << message
  end
  def go_to_game(game)
    unless @games.include? game
      raise KeyError.new
    end
    if game != @current_game and @current_game != nil
      post 'Du befinner dig nu i %s.' % game.name
    end
    @current_game = game
  end
  def join_game(game)
    game.add_person(self)
    @games << game
    post 'Du är nu med i %s.' % game.name
    go_to_game(game)
    post game.status
  end
  def maybe_go_to_other_game
    unless @games.include? @current_game
      unless @games.empty?
        go_to_game @games.first
      else
        @current_game = nil
      end
    end
  end
  def eliminated_from(game)
    @games.delete(game)
    maybe_go_to_other_game
  end
  def participates_in_a_game!
    raise CommandError.new('Du deltar inte i något parti!') unless @current_game
  end

  ##################################################

  def help(words = nil)
    text = "Jag leder partier av ett spel inte helt olikt Risk.\n\nFraser jag potentiellt begriper:\n"
    phrases = ["partier", "nytt parti [SPEL]", "deltag i [SPEL]", "börja", "kort ...", "placera ...",
      "anfall ...", "flytta ...", "klar", "lämna [SPEL]", "kapitulera", "karta [SPEL]", "gränser",
      "säg TEXT", "elisphack", "gå till [SPEL]", "inställningar", "sätt NAMN [= VÄRDE]"].sort
    text << phrases.column_list_view
    text << "\n\nNamn och fraser går att kom-förkorta varhelst man vill."
    text << "\n\nFramför klagomål till <person 9023: Nicklas Lindgren (Äter mopeder, öppnar kasino)>\n\nGurk. Ost."
    post text
  end
  def elisphack(words = nil)
    text = "Praktiska saker för elisp-klienten:\n\n"
    text << "Bind s g till att sända ett meddelande till mig:\n"
    text << "  (add-hook 'lyskom-mode-hook (lambda () (local-set-key [?s ?g] (lambda nil (interactive) (kom-send-message 12668)))))"
    post text
  end
  def new_game(words = nil)
    if @games.length >= 17
      post 'Ge dig! %s aktiva partier borde räcka för vem som helst.' % @games.length.swedish.capitalize
      return
    end
    g = $state.new_game(words)
    g.add_person(self)
    @games << g
    post "Du har skapat %s." % g.name
    go_to_game(g)
    post g.settings_status
  end
  def go_to(words = [])
    go_to_game @games.pick_from(words, 'partier')
  end
  def join(words = [])
    join_game $state.open_games.pick_from(words, 'öppna partier')
  end
  def leave(words = [])
    game = @games.pick_from(words, 'partier')
    if game.started
      post 'Spelet är påbörjat. Du måste kapitulera istället.'
    else
      game.remove_person(self)
      @games.delete(game)
      maybe_go_to_other_game
    end
  end
  def settings(words = [])
    participates_in_a_game!
    post @current_game.settings_status
  end
  def set(words = [])
    participates_in_a_game!
    setting, rest = @current_game.settings.pick_from_with_rest(words, 'inställningar')

    if rest.empty?
      post setting.status
    elsif rest[0] == '='
      @current_game.set(self, setting, rest[1..-1])
    end
  end
  def say(text)
    participates_in_a_game!
    if text
      @current_game.post_to_everybody('%s säger till %s: %s' % [name, @current_game.name, text])
    end
  end
  def ready(words = nil)
    participates_in_a_game!
    @current_game.ready_person(self)
  end
  def surrender(words = [])
    participates_in_a_game!
    unless @current_game.started
      leave
    else
      @current_game.surrender_person(self)
    end
  end
  def status(words = nil)
    if @games.empty?
      post 'Du deltar inte i några partier.'
    else
      other_games = @games.reject { |g| g == @current_game }
      post "Du befinner dig för närvarande i:\n  " + @current_game.name if @current_game
      post "Du deltar också i:\n" + other_games.names.sort.list_view unless other_games.empty?
    end
    post $state.status
  end
  def statistik(words = [])
    raise CommandError.new('Oimplementerat a: ' + words.join(' '))
  end
  def info(words = [])
    raise CommandError.new('Oimplementerat b: ' + words.join(' '))
  end
end

######################################################################
#  __  __
# |  \/  | __ _ _ __
# | |\/| |/ _` | '_ \
# | |  | | (_| | |_) | _ _
# |_|  |_|\__,_| .__(_|_|_)
#              |_|

class Mission
  def initialize(game, player, params={})
    @params = params
    if @params[:kill_player]
      @params[:kill_player] = game.players[@params[:kill_player]]
    end
    @params[:continents] = @params[:continents].collect { |c| game.map.continents[c] }
  end
  def evaluate_victory
    false
  end
  def to_s
    result = []
    if @params[:kill_player]
      result << 'utplåna %s' % @params[:kill_player].name
    end
    if not @params[:continents].empty?
      continents = 'erövra %s' % @params[:continents].names.swedish
      if @params[:n_continents] > @params[:continents].length
        continents << ', samt ytterligare %s' % (@params[:n_continents] - @params[:continents].length).swedish_quantity('valfri kontinent', 'valfria kontinenter')
      end
      result << continents
    elsif @params[:n_continents] > 0
      result << 'erövra %s' % (@params[:n_continents] - @params[:continents].length).swedish_quantity('valfri kontinent', 'valfria kontinenter')
    end
    if @params[:n_countries] > 0
      result << 'erövra %d valfria länder' % @params[:n_countries]
    end
    if @params[:min_armies] > 0
      result << 'placera minst %d arméer i varje land' % @params[:min_armies]
    end
    result.swedish.capitalize + '.'
  end
end

class Country
  attr_reader :name
  attr_accessor :owner, :armies, :continent, :borders
  def initialize(name)
    @name = name
    @owner = nil
    @armies = 0
    @continent = nil
    @borders = []
  end
  def map_string(secret_except_for = nil)
    result = @owner ? @owner.symbol : '?'
    if secret_except_for and secret_except_for != @owner
      result << ' ?'
    else
      result << '%2d' % @armies
    end
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

class Map
  FORMAT_STRING = '~~~~~~~~~~~~_____~~~______________~~~~~~~~~~~~~~~~~~~__________~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~/     \~/              \~~~~~~~~~~~~~~~~~/     /    \~~~~~___~~~~~~~~~~_________~~~~
~~______~~~\_____/~\__    %3s   __/~~~~~~~~~~~~~~~~/     /  ___/~~~~/   \________/        /~~~~
~/      \__________~~~\__      /~~____~~~~~~~~~~~_/      \  \______/    /       /     ___/~~~~~
/  %3s  /     /   /~~~~~~\    /~~/    \~~~~~~~~~/         \  \     \    \  %3s /  %3s \~~~~~~~~
\____  / %3s /   /~~~~___~\__/~~/ %3s /~~____~~/     /\    \  \     \    \_____\    /\ \~~~~~~~
~~~~~\ \____/    \~~~/   \~~~~~~\____/~~/   /~/ %3s /~~\___/  /      \    \     \   \~\_\~___~~
~~~~~~\/    \ %3s \_/ %3s \~~~~~~~~~~___\  /~~\     \~~~__/   \  %3s  \    \ %3s \   \~~~/   \~
~~~~~~~\ %3s \     \      /~__~~~~~~/  // /~~~~\   _/~~/       \       \_   \__   \   \~~\  __\\
~~~~~~~/______\____/_____/_/ /~~~~~~\_//  \_~~~~\_/~~~/         \        \     \___\__ \~~\ \~~
~~~~~~/          \          /~~~~~~~~~/ %3s \~~~_____/    %3s    \______  \ %3s \     \ \~/  \~
~~~~~~\           \   %3s  /~~~~~~~~~~\_____/~~/   \             /      \  \    / %3s /\//    \\
~~~~~~~\   %3s    /    __  \~~~~~~~~~~~~______/ %3s \__        _/_       \__\___\    /~~/ %3s /
~~~~~~~~\        /____/~~\__\~~~~~~~~~~~\     \_____/  \      /~~~\       \      \__ \~~\   _/~
~~~~~~~~~\______/   /~~~~~~~~~~~~~~~~~__/ %3s /         \___  \~~~/  %3s  /         \_\~~\_/~~~
~~~~~~~~~~\_       /~__~~~~~~~~~~~~~~/     __/__ %3s /\_/~~~\  \~~\      /    %3s     /~~~~~~~~
~~~~~~~~~~~~\  %3s \/ /~~~~~~~~~~~~~~\____/~~~~/____/~~~____/___\_/      \           /~~~~~~~~~
~~~~~~~~~~~~~\       /~~~~~~~~~~~~~~~~____~~~~~~~~~~~~~/          \_______\____     /~~~~~~~~~~
~~~~~~~~~~~~~~\___   \~~~~~~~~~~~~~~~/    \__________~~\___  %3s      /        \___/_~~~~~~~~~~
~~~~~~~~~~~~~~~~~~\___\~~~~~~~~~~~~~/          /     \~~__/   _______/        _/     \~~~~~~~~~
~~~~~~~~~~~~~~~___/    \____~~~~~~~/    %3s   /  %3s  \/      \__~~~~\  %3s  /~\ %3s /~~~~~~~~~
~~~~~~~~~~~~~~/    %3s     _\~~~~~/           \        \        /~~~~~\     /~~~\   /~~~~~~~~~~
~~~~~~~~~~~~~/____________/  \~~~~\      ______\_______/\______/~~~~~~~\   /~~~~~\_/~~~~~~~~~~~
~~~~~~~~~~~~~\     \          \~~~~\____/_    \        \___~~~~~~~~~~~~~\_/~~~~~~___~~~~___~~~~
~~~~~~~~~~~~~~\ %3s \_  %3s   /~~~~~~~~~~~\    \   %3s    /~~~~~~~~~~~~~~~~~~~~_/   \~~/   \__~
~~~~~~~~~~~~~~~\______\      /~~~~~~~~~~~~/ %3s \        /~____~~~~~~~~~~~~~~~/  %3s \~\ %3s  \\
~~~~~~~~~~~~~~~~\     /   __/~~~~~~~~~~~~~\      \______/~/    \~~~~~~~~~~~~~~\______/~~\_____/
~~~~~~~~~~~~~~~~/     \__/~~~~~~~~~~~~~~~~~\_____/     /~/ %3s_/~~~~~~~~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~~~/ %3s  /~~~~~~~~~~~~~~~~~~~~~~\        /~/    /~~~~~~~~~~~~~~~____/     __/  \~~
~~~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~~~~~~\  %3s  \~\___/~~~~~~~~~~~~~~~/     %3s /      \~
~~~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~~~~~~\      /~~~~~~~~~~~~~~~~~~~~~\        /  %3s  /~
~~~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~~~~~~\____/~~~~~~~~~~~~~~~~~~~~~~/_______/_______/~~'

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
    [6,9,18,21,22,25], [2,9,10,16,23], [7,8,17], [3,10,14,19,23],
    [7,11,15,24], [6,12,13,20,22], [3,16], [12,18,22,26],
    [9,13,23,25,28], [13,18,20,25,26,27], [9,14,16,21,28,29], [17,30],
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

  STARTING_ARMIES = {2 => 40, 3 => 35, 4 => 30, 5 => 25, 6 => 20}

  MISSIONS = ([ {:kill_player => 0, :continents => [], :n_continents => 0, :n_countries => 0, :min_armies => 0},
                {:kill_player => 1, :continents => [], :n_continents => 0, :n_countries => 0, :min_armies => 0},
                {:kill_player => 2, :continents => [], :n_continents => 0, :n_countries => 0, :min_armies => 0},
                {:kill_player => 3, :continents => [], :n_continents => 0, :n_countries => 0, :min_armies => 0},
                {:kill_player => 4, :continents => [], :n_continents => 0, :n_countries => 0, :min_armies => 0},
                {:kill_player => 5, :continents => [], :n_continents => 0, :n_countries => 0, :min_armies => 0},
                {:kill_player => nil, :continents => [2, 3], :n_continents => 2, :n_countries => 0, :min_armies => 0},
                {:kill_player => nil, :continents => [2, 4], :n_continents => 2, :n_countries => 0, :min_armies => 0},
                {:kill_player => nil, :continents => [0, 4], :n_continents => 2, :n_countries => 0, :min_armies => 0},
                {:kill_player => nil, :continents => [0, 5], :n_continents => 2, :n_countries => 0, :min_armies => 0},
                {:kill_player => nil, :continents => [1, 3], :n_continents => 3, :n_countries => 0, :min_armies => 0},
                {:kill_player => nil, :continents => [1, 5], :n_continents => 3, :n_countries => 0, :min_armies => 0},
                {:kill_player => nil, :continents => [], :n_continents => 0, :n_countries => 18, :min_armies => 2},
                {:kill_player => nil, :continents => [], :n_continents => 0, :n_countries => 24, :min_armies => 0} ])

  FALLBACK_MISSION = {:kill_player => nil, :continents => [], :n_continents => 0, :n_countries => 24, :min_armies => 0}

  attr_reader :countries, :continents
  def initialize
    @countries = COUNTRY_NAMES.collect { |n| Country.new(n) }
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
  def view(secret_except_for = nil)
    FORMAT_STRING % @countries.collect { |c| c.map_string(secret_except_for) }
  end
  def missions(n_players)
    MISSIONS[1..n_players] + MISSIONS[7..-1]
  end
end

######################################################################
#   ____
#  / ___| __ _ _ __ ___   ___
# | |  _ / _` | '_ ` _ \ / _ \
# | |_| | (_| | | | | | |  __/_ _ _
#  \____|\__,_|_| |_| |_|\___(_|_|_)

class Player
  attr_reader :person
  attr_accessor :ready
  attr_accessor :active
  attr_accessor :state
  attr_accessor :countries
  attr_accessor :mission
  attr_accessor :cards
  def initialize(game, person)
    @game = game
    @person = person
    @ready = false
    @active = true
    @state = nil
    @countries = []
  end
  def name
    @person.name
  end
  def recieve_country(country)
    @countries << country
    country.owner = self
  end
  def post(msg)
    @person.post(msg)
  end
end

######################################################################

class Game
  attr_reader :name
  attr_reader :started
  attr_reader :ended
  attr_reader :round
  attr_reader :players
  attr_reader :settings
  attr_reader :map

  def initialize(name)
    @name = name
    @started = false
    @ended = false
    @round = 0
    @players = []
    @settings = [GameTypeSetting.new, TimeoutSetting.new]
    @settings_hash = @settings.inject({}){|h, s| h.merge({s.class => s})}
    @map = nil
    @turn_queue = []
  end
  def brief_status
    result = "  %s\n" % @name
    @players.each do |person, player|
      result << "   | %s\n" % person.long_name
    end
    result
  end
  def settings_status
    "Spelinställningar:\n" + @settings.collect{|s| s.brief_status}.join
  end
  def set(person, setting, value_words)
    if started
      raise CommandError.new('Spelinställningarna kan inte ändras i ett pågående parti!')
    end
    setting.set value_words
    post_to_everybody('%s satte "%s" till "%s" i %s.' % [ person.name, setting.name, setting.to_s, name ])
    nobody_is_ready
  end
  def status
    "%s\n%s" % [ brief_status, settings_status ]
  end
  def players
    @players.collect { |person, player| player }
  end
  def max_players
    6
  end

  ##################################################

  def add_person(person)
    if @players.length >= max_players
      raise CommandError.new('%s är fullt!' % name)
    elsif people.include? person
      raise CommandError.new('Du deltar redan i partiet!' % name)
    else
      player = Player.new(self, person)
      @players << [person, player]
      post_to_everybody_except(person, '%s har gått med i %s.' % [ person.name, name ])
    end
    nobody_is_ready
  end
  def remove_person(person)
    if started
      raise CommandError.new('Spelet har redan börjat! Du måste "kapitulera" istället.')
    end
    post_to_everybody('%s har lämnat %s.' % [ person.name, name ])
    @players.reject! { |p, player| person == p }
    if @players.empty?
      person.post('%s har upphört.' % name)
      $state.delete_game self
    else
      nobody_is_ready
    end
  end
  def ready_person(person)
    if @players.length == 1
      raise CommandError.new('Spelet behöver mer än en deltagare!')
    end
    player(person).ready = true
    post_to_everybody('%s är redo att börja %s.' % [person.name, name])
    unready_players = players.select { |p| not p.ready }
    if unready_players.empty?
      start_game
    else
      post_to_everybody("Väntar på följande spelare:\n" + unready_players.names.list_view)
    end
  end
  def surrender_person(person)
    unless started
      raise CommandError.new('Spelet har inte startat än.')
    end
    post_to_everybody('%s har kapitulerat!' % person.name)
    player = player(person)
    player.state = :surrendered
    eliminate_player(player(person))
    evaluate_victory
  end
  def post_to_everybody(message)
    people.each do |person|
      person.post message
    end
  end

  ##################################################
  private

  def nobody_is_ready
    @players.each do |person, player|
      if player.ready
        player.ready = false
        person.post('Du måse säga "börja" igen om du är redo!')
      end
    end
  end
  def people
    @players.collect { |person, player| person }
  end
  def player(person)
    @players.assoc(person).last
  end
  def active_players
    players.select { |p| p.active }
  end

  def start_game
    post_to_everybody('%s har börjat!' % name)
    @started = true
    @map = Map.new
    if @settings_hash[GameTypeSetting].get == :mission
      missions = @map.missions(@players.length).choose(@players.length)
      players.zip(missions).each do |player, mission|
        player.mission = Mission.new(self, player, mission)
        player.post('Ditt uppdrag: %s' % player.mission)
      end
    end
  end
  def eliminate_player(player)
    player.person.eliminated_from(self)
    player.active = false
    unless ended

    end
  end
  def evaluate_victory
    a = active_players
    if a.length == 1
      a[0].state = :victor
      post_to_everybody('%s har segrat i %s!' % [ a[0].name, name ])
      @ended = true
      eliminate_player a[0]
    end
  end
  def post_to_everybody_except(person, message)
    people.reject{|p| p == person}.each do |p|
      p.post message
    end
  end

end

######################################################################

class State < Monitor
  attr_reader :store
  def initialize
    @store = PStore.new('generalen.state')
    @store.transaction do
      unless @store[:inited]
        @store[:people] = {}
        @store[:games] = []
        @store[:last_game_number] = 0
        @store[:inited] = true
      end
    end
    super
  end

  Commands = ({ ['elisphack'] => :elisphack,
                ['nytt', 'parti'] => :new_game,
                ['deltag', 'i'] => :join,
                ['gå', 'till'] => :go_to,
                ['status'] => :status,
                ['partier'] => :status,
                ['lämna'] => :leave,
                ['inställningar'] => :settings,
                ['sätt'] => :set,
                ['säg'] => :say,
                ['börja'] => :ready,
                ['kapitulera'] => :surrender,
                ['statistik'] => :statistik,
                ['information'] => :statistik,
                ['information', 'om'] => :info })

  def command(from_person, cmd)
    synchronize do
      @store.transaction do
        if cmd == :login
          if @store[:people].has_key?(from_person)
            flush
          end
          return
        end
        words = cmd.scan(/[[:punct:]]+|[^[:space:][:punct:]]+/)
        raw = cmd.gsub(/^\s*[^[:space:][:punct:]]+\s*/, '')
        return if words.empty?
        person = get_person(from_person)

        alts = Commands.prefix_words_matches(words)
        begin
          if alts.empty?
            person.help
          elsif alts.length > 1
            raise AlternativesError.new(alts)
          elsif Commands[alts[0].first] == :say
            person.say(raw)
          else
            person.send(Commands[alts[0].first], alts[0].last)
          end
        rescue CommandError => e
          person.post e.message
        end

        flush
      end
    end
  end

  def new_game(name_words = nil)
    @store[:last_game_number] += 1
    if not name_words or name_words.empty?
      name = @store[:last_game_number].swedish(:ordinal => true).capitalize + ' partiet'
    else
      name = name_words.join(' ')
    end
    g = Game.new(name)
    @store[:games] << g
    g
  end
  def delete_game(game)
    @store[:games].delete(game)
  end

  def open_games
    @store[:games].select { |g| not g.started }
  end
  def status
    not_started = open_games
    started = @store[:games].select { |g| g.started and not g.ended }
    #ended = @store[:games].select { |g| g.ended }
    result = []

    if not_started.empty?
      result << 'Det finns inga öppna partier. Prova med "nytt parti"!'
    else
      result << "Öppna spel:\n" + not_started.collect{|g| g.brief_status}.join
    end
    unless started.empty?
      result << "Påbörjade spel:\n" + started.collect{|g| g.brief_status}.join
    end
    #     if not ended.empty?
    #       result << "Nyligen avslutade spel:\n" + not_started.collect{|g| g.brief_status}.join
    #     end
    result.join "\n\n"
  end

  private

  def flush
    @store[:people].each do |id, person|
      next if person.messages.empty?
      if id == :admin
        puts "\n"
        puts person.all_messages
        person.messages.clear
      else
        if $kombot
          begin
            $kombot.send_message(id, person.all_messages)
          rescue Kom::MessageNotSent
          else
            person.messages.clear
          end
        end
      end
    end
  end

  def get_person(person_id)
    person = @store[:people][person_id]
    unless person
      person = @store[:people][person_id] = Person.new(person_id)
    end
    person
  end

end

######################################################################

class KomBot
  include Kom

  def initialize(params = {})
    @params = {
      :unix_user => 'kom.rb',
      :port => 4894,
      :client_name => 'KomBot.rb',
      :client_version => '0.1.0',
      :invisible => 1 }.merge(params)
  end
  def run
    @conn = CachedConnection.new(@params[:server],
                                 @params[:port],
                                 @params[:unix_user])
    ReqLogin.new(@conn,
                 @params[:person],
                 @params[:password],
                 @params[:invisible]).response
    ReqSetClientVersion.new(@conn,
                            @params[:client_name],
                            @params[:client_version])

    async_callbacks = []
    methods.each do |m|
      begin
        if Kom.const_defined? m.upcase
          async = Kom.const_get(m.upcase)
          @conn.add_async_handler(async, method(m))
          async_callbacks << async
        end
      rescue NameError
      end
    end
    ReqAcceptAsync.new(@conn, async_callbacks).response

    loop do
      data = select([@conn.socket], [], [], @params[:periodic_timeout])
      if data
        @conn.parse_present_data()
      else
        periodic
      end
    end
  end

  def send_message(person, msg)
    ReqSendMessage.new(@conn, person, msg).response
  end

  def conf_name(person)
    @conn.conf_name(person)
  end

  private

  def periodic
  end
end

######################################################################

class Generalen < KomBot
  def initialize(params = {})
    super(params.merge({ :unix_user => 'generalen',
                         :client_name => 'generalen.rb',
                         :client_version => '0.1.0',
                         :periodic_timeout => 10 }))
  end

  def async_send_message(msg, c)
    if msg.recipient == @params[:person]
      $logger.info "send_message %s" % [c.conf_name(msg.sender)]
      $state.command(msg.sender, msg.message)
    end
  end

  def async_login(msg, c)
    $logger.info "login %s" % [c.conf_name(msg.person_no)]
    $state.command(msg.person_no, :login)
  end
end

######################################################################

$logger = Logger.new(File.new('generalen.log', 'w+'), 10, 1024**2)
$state = State.new

Thread.abort_on_exception = true

begin
  kom_thread = Thread.new do
    loop do
      begin
        cmd = Readline.readline('generalen> ', true)
        if cmd and not cmd.empty?
          if cmd =~ (/^:/)
            puts eval(cmd[1..-1])
          else
            $state.command(:admin, cmd)
          end
        end
      rescue Exception => e
        puts e
      end
    end
  end
  $kombot = Generalen.new(:server => 'kom.lysator.liu.se',
                          :person => 12668,
                          :password => '64llob')
  $kombot.run
  kom_thread.join
rescue Interrupt
  puts
end
