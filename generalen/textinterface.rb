# -*- coding: iso-8859-1 -*-
#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det h�r programmet distribueras under villkoren i GPL v2.
#++

require 'util/view'
require 'util/swedish'

module Enumerable
  def pick_from_with_rest(words, type = 'alternativ')
    pick_from(words, type, true)
  end

  def pick_from(words, type = 'alternativ', rest = false)
    hash = name_hash
    alts = hash.prefix_words_matches(words)
    if alts.length != 1
      raise TextInterface::AlternativesError.new(alts, words, type)
    end
    if rest
      [hash[alts[0].first], alts[0].last]
    else
      hash[alts[0].first]
    end
  end
end

######################################################################

module TextInterface
  class CommandError < Exception; end
  class NoCurrentGameException < CommandError; end

  attr_accessor :current_game

  class AlternativesError < CommandError
    def initialize(alts, words, name = 'alternativ')
      if alts.empty?
        @alts = 'Din inmatning "%s" matchar inga %s!' % [ words.join(' '), name ]
      else
        @alts = "Vilket av f�ljande %s menar du?\n%s" % [ name,  alts.collect{ |a| a.first.join(' ') }.sort.column_list_view ]
      end
    end
    def message
      @alts
    end
  end
  STANDARD_MAP = '~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   %3s   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ %3s /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  %3s / %3s \~~~~~~~
\__  / %3s /   /~~~___~\/~/ %3s /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ %3s /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ %3s \/ %3s \~~~~~~___\  /~~\     \~~/  \ %3s \   \ %3s \  \~~/   \~
~~~~~\ %3s \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ %3s \~~~____/   %3s  \___  \ %3s /    \/~/  \~
~~~~\           \  %3s /~~~~~~~\_____/~~/   \          /  \  \   / %3s /~/    \\
~~~~~\   %3s    /  __  \~~~~~~~~~______/ %3s \_     __/    \__\__\    /~/ %3s /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ %3s /        \_ \~~/ %3s /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ %3s __/~\ \~\    /    %3s    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ %3s  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ %3s  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    %3s   \ %3s \/   \__~\  %3s  /\ %3s /~~~~~~~~
~~~~~~~~~~~~/    %3s   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ %3s \_ %3s  /~~~~~~~~\    \  %3s   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ %3s \      /~____~~~~~~~~~~/ %3s \~\ %3s \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ %3s_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ %3s  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ %3s \~\___/~~~~~~~~~~/   %3s /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  %3s  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~
'

  INITIALS = ['#', 'X', 'O', '%', '@', '�']

  def map_str(map, names=false)
    if map.name != :standard
      raise ArgumentError.new('Ok�nd karttyp')
    else
      if names
        STANDARD_MAP % map.countries.collect do |c|
          words = c.name.split
          if words.length ==1
            words.first[0..2]
          else
            '%s %s' % [ words[0][0..0], words[1][0..0] ]
          end
        end
      else
        result = STANDARD_MAP % (if map.game.open
                                   [' ? '] * map.countries.length
                                 else
                                   map.countries.collect do |c|
                                     (c.owner ? INITIALS[c.owner.number] : '-') +
                                       if c.owner && c.owner.person != self and not map.game.first_placement_done
                                         ' ?'
                                       elsif c.owner && c.owner.person != self
                                         '%2d' % c.armies
                                       else
                                         '%2d' % c.total_armies
                                       end
                                   end
                                 end)
        result << "  %s%s%s\n" % [ map.game.name, (map.game.round > 0 ? ', omg�ng %d' % map.game.round : ''), deadline_str(map.game) ]
        map.game.initial_turn_order.each do |player|
          result << "  (%s) %s%s\n" % ([ INITIALS[player.number],
                                         player.name,
                                         player_info_str(player, player.person == self) ])
          result << "    %s, %s%s (%s)\n" % ([ cards_str(player.cards, !player.game.finished),
                                               player.countries.length.swedish_quantity('land', 'l�nder', :neutrum => true),
                                               continents_str(player.continents),
                                               armies_str(player) ])
          if player.mission and not map.game.active
            result << "    Uppdrag: %s\n" % player.mission.swedish
          end
        end
        if map.game.started
          country_distribution = map.game.initial_turn_order.collect{ |p| [INITIALS[p.number], p.countries.length] }
          army_distribution = map.game.initial_turn_order.collect{ |p| [INITIALS[p.number], p.armies] }
          plus_distribution = map.game.initial_turn_order.collect{ |p| [INITIALS[p.number], p.bonus_armies] }
          total_pluses = map.countries.length / 3 + map.continents.inject(0){ |acc, c| acc + c.bonus_armies }
          remaining = total_pluses - plus_distribution.inject(0){ |acc, p| acc + p.last }
          plus_distribution << ['-', remaining]

          result << ' '*9 + (['.']*5).join(' '*16) + "\n"
          result << " L�nder [%s]\n" % distribution_graph(country_distribution, 69)
          result << " Arm�er [%s]\n" % distribution_graph(army_distribution, 69)
          result << '   Plus [%s]' % distribution_graph(plus_distribution, 69)
        end
        return result
      end
    end
  end

  def deadline_str(game)
    if game.turn_deadline and not game.finished
      remaining = game.turn_deadline - Time.now
      return ' [%s]' % (if remaining <= 0
                          'Deadline passerad!'
                        elsif remaining > 3600
                          '%d timmar till dragdeadline' % (remaining / 3600)
                        elsif remaining > 60
                          '%d minuter till dragdeadline' % (remaining / 60)
                        else
                          'Cirka %d sekunder till dragdeadline' % ((remaining / 10).round * 10)
                        end)
    else
      ''
    end
  end

  def player_info_str(player, current = false, short = false)
    result = ''
    if player.surrendered
      result << ' [Har kapitulerat]'
    elsif player.winner
      result << ' [Vinnare!]'
    elsif player.loser
      result << ' [Besegrad]'
    end
    if player.game.in_turn(player.person) and player.game.first_placement_done and not player.game.finished
      result << ' [I tur]'
      return result if short
      parts = []
      if player.game.turn_phase == 0
        if current
          parts << '%d att placera' % player.armies_for_placement if player.armies_for_placement != 0
        else
          parts << '%d att placera' % player.bonus_armies
        end
      end
      if player.armies_for_movement != 0
        parts << '%d att flytta' % player.armies_for_movement
      end
      result << ' [%s]' % parts.join(', ') unless parts.empty?
    elsif not player.game.first_placement_done and player.game.in_turn(player.person)
      if current
        result << ' [%d att placera]' % player.armies_for_placement
      else
        result << ' [Ska placera arm�er]'
      end
    end
    if player.game.open and player.ready
      result << ' [Redo att b�rja]'
    end
    return result
  end

  def cards_str(cards, secret = false)
    n_cards = cards.values.inject(0){ |a,b| a+b }
    if secret or n_cards == 0
      n_cards.swedish_quantity('kort', 'kort', :neutrum => true).capitalize
    else
      cards.collect.sort.collect{ |c, n| (['[%s]' % c.to_s.upcase] * n).join(' ') }.reject{ |s| s.empty? }.join(' ')
    end
  end

  def continents_str(continents)
    if continents.empty?
      ''
    else
      ' inklusive hela %s' % continents.collect{ |c| c.name }.swedish
    end
  end

  def armies_str(player)
    '%d, %+d' % [ player.armies, player.bonus_armies ]
  end

  def distribution_graph(segments, width)
    total = segments.inject(0){ |acc, seg| acc + seg.last }
    result = ''
    segments.each do |character, value|
      result << character * (width * value).quo(total).round if value > 0
    end
    if result.length < width
      result << segments.last.first * (width - result.length)
    end
    if result.length > width
      result = result[0...width]
    end
    return result
  end

  def game_str(game)
    result = "  %s\n" % game.name
    result << game.people_players.collect do |person, player|
      '   | ' + person.name + player_info_str(player, false, true)
    end.join("\n")
  end

  def post_map(game)
    post_map_message(map_str(game.map))
  end

  class GameObserver
    attr_reader :game
    def initialize(person, game)
      @person = person
      @has_been_ready = false
      @ready = false
      @end_announced = false
      @game = game
      game.add_observer(self)
    end
    def maybe_request_ready
      if not @ready and @game.players.length > 1
        if @has_been_ready
          if @person.current_game != game
            @person.post('Du m�ste g� till %s och skriva "b�rja" igen om du �r redo.' % @game.name)
          else
            @person.post('Du m�ste skriva "b�rja" igen om du �r redo.')
          end
        else
          if @person.current_game != game
            @person.post('G� till %s och skriv "b�rja" om du �r redo att b�rja partiet.' % @game.name)
          else
            @person.post('Skriv "b�rja" om du �r redo att b�rja partiet.')
          end
        end
      end
    end
    def maybe_prompt_for_history
      if @person.has_delayed?(@game)
        @person.post 'Skriv "resum�" om du vill veta vad som h�nt.'
      end
    end
    def maybe_auto_switch_game
      in_turn_game = @person.games.values.detect{ |g| g.game.in_turn(@person) }
      if in_turn_game
        games = @person.games.values.select{ |g| g.game.in_turn(@person) }
        games = games.sort{ |a, b| (a.turn_deadline || Float.max) <=> (b.turn_deadline || Float.max) }
        @person.go_to_impl(games.first.game)
      end
    end
    def player
      @game.people_players[@person]
    end
    def dice_text(dice)
      dice.collect{ |d| '[%d]' % d }.join(' ')
    end
    def may_auto_change_game?
      if @person.current_game
        @person.current_game != @game and not @person.current_game.in_turn(@person)
      else
        true
      end
    end
    def update(type, params = {})
      case type
      when :join
        @person.post('%s har g�tt med i %s.' % [ params[:person].name, @game.name ])
        maybe_request_ready
      when :leave
        @person.post('%s har l�mnat %s.' % [ params[:person].name, @game.name ])
        maybe_request_ready
      when :ceased
        if not @end_announced
          @person.post('%s har upph�rt.' % [ @game.name ])
          @end_announced = true
        end
      when :set
        @person.post('%s har satt %s till %s i %s.' % [ params[:by_person].name, params[:setting].name, params[:setting], @game.name ])
        maybe_request_ready
      when :ready
        @person.post('%s �r redo att b�rja i %s.' % [ params[:person].name, @game.name ])
        if params[:person] == @person
          @has_been_ready = true
          @ready = true
        end
        if not params[:not_ready].empty?
          waiting_message = "V�ntar p� f�ljande spelare:\n"
          waiting_message << params[:not_ready].collect{ |n| '  '+n.name }.join("\n")
          @person.post(waiting_message)
        end
      when :done
        @person.post('%s �r klar med sina f�rsta utplaceringar i %s.' % [ params[:person].name, @game.name ])
        if not params[:not_done].empty?
          waiting_message = "V�ntar p� f�ljande spelare:\n"
          waiting_message << params[:not_done].collect{ |n| '  '+n.name }.join("\n")
          @person.post(waiting_message)
        end
        if params[:person] == @person
          maybe_auto_switch_game
        end
      when :nobody_ready
        @ready = false
      when :started
        @person.post('%s har b�rjat!' % @game.name)
        order_message = "Turordningen slumpas till:\n"
        order_message << @game.turn_queue.select{ |n| n != :new_round }.collect{ |n| '  '+n.name }.join("\n")
        @person.post(order_message)
        if player.mission
          @person.post_mission(player.mission)
        end
        countries = player.countries
        @person.post("Du tilldelas %s: %s.\n\nDu har %s att placera ut." % ([ countries.length.swedish_quantity('land', 'l�nder', :neutrum => true),
                                                                              countries.collect{ |c| c.name }.sort.swedish,
                                                                              player.armies_for_placement.swedish_quantity('arm�', 'arm�er') ]))
        if may_auto_change_game?
          @person.go_to_impl(@game)
        end
      when :surrender
        @person.post('--- %s har kapitulerat i %s! ---' % [ params[:person].name, @game.name ])
      when :defeated
        @person.post('--- %s �r besegrad i %s! ---' % [ params[:person].name, @game.name ])
        if params[:n_cards] and params[:n_cards] > 0
          if params[:by_person] == @person
            @person.post('Du �vertar f�ljande kort: %s' % @person.cards_str(params[:cards]))
          else
            @person.post('%s �vertar %s.' % [ params[:by_person].name, params[:n_cards].swedish_quantity('kort', 'kort', :neutrum => true) ])
          end
        end
      when :winner
        @person.post('--- %s har vunnit %s! ---' % [ params[:person].name, @game.name ])
        maybe_prompt_for_history
        @end_announced = true
      when :say
        @person.post("%s [%s]:\n%s" % [ params[:person].name, @game.name, params[:text] ])
      when :turn_timeout
        @person.post('Tiden �r ute f�r %s i %s!' % ([ (@game.first_placement_done ? @game.turn_queue.first.name : 'placering'),
                                                      @game.name ]))
      when :turn_change
        if params[:to_person] == @person
          @person.post_map(@game)
          @person.post('*** Det �r din tur i %s! ***' % @game.name)
          maybe_prompt_for_history
          @last_attack = nil
          @last_move = nil
          if player.armies_for_placement > 0
            @person.post('Du har %s nya arm�er att placera ut.' % player.armies_for_placement.swedish_quantity('ny arm�', 'nya arm�er'))
          else
            @person.post('Du f�r inga arm�er f�rsta rundan, men du kan "anfalla", sedan "flytta" eller anse dig vara "klar".' % player.armies_for_placement)
          end
          if player.total_cards >= 5
            @person.post('Du m�ste anv�nda en upps�ttning kort den h�r omg�ngen.')
          end
          if may_auto_change_game?
            @person.go_to_impl(@game)
          end
        else
          message = 'Turen �verg�r till %s i %s.' % [ params[:to_person].name, @game.name ]
          if params[:from_person] == @person
            @person.post_map(@game)
            maybe_auto_switch_game
            @person.post(message)
          else
            @person.post_maybe_delayed(@game, message)
          end
        end
      when :cards
        @person.post_map(@game) if params[:player] == player
        message = "%s:\n%s f�r %s f�r f�ljande kort: %s" % ([ @game.name,
                                                              params[:person].name,
                                                              params[:armies].swedish_quantity('extra arm�', 'extra arm�er'),
                                                              @person.cards_str(params[:cards]) ])
        @person.post_maybe_delayed(@game, message, params[:player] != player)
      when :place
        if not params[:placements].empty?
          @person.post_map(@game) if params[:player] == player
          message = "%s:\n  %s placerar ut f�ljande arm�er:\n" % [ @game.name, params[:person].name ]
          message << params[:placements].sort.collect do |country, armies|
            '%23s %2d + %2d = %2d' % [ country.name, country.armies - armies, armies, country.armies ]
          end.join("\n")
          @person.post_maybe_delayed(@game, message, params[:person] != @person)
        end
      when :attack
        @person.post_map(@game) if params[:player] == player
        message = "%s:\n  %23s - %s\n                     anfaller\n  %23s - %s\n\n" % ([ @game.name,
                                                                                          params[:from].name,
                                                                                          params[:from].owner.person.name,
                                                                                          params[:target].name,
                                                                                          params[:target].owner ? params[:target].owner.person.name : 'Neutral' ])
        message << "   Anfall: %-11s   %23s: %2d - %2d = %2d\n  F�rsvar: %-11s   %23s: %2d - %2d = %2d" %
            ([ dice_text(params[:attack]),
               params[:from].name,
               params[:from].armies + params[:attacker_losses],
               params[:attacker_losses],
               params[:from].armies,
               dice_text(params[:defence]),
               params[:target].name,
               params[:target].armies + params[:defender_losses],
               params[:defender_losses],
               params[:target].armies ])
            @person.post_maybe_delayed(@game, message, params[:player] != player)
      when :conquer
        @person.post_map(@game) if params[:player] == player
        message = "%s er�vrar %s!\n\n" % [ params[:target].owner.person.name, params[:target].name ]
        message << "%23s: %2d - %2d = %2d\n%23s: %2d + %2d = %2d" % ([ params[:from].name,
                                                                       params[:from].armies + params[:armies],
                                                                       params[:armies],
                                                                       params[:from].armies,
                                                                       params[:target].name,
                                                                       0,
                                                                       params[:armies],
                                                                       params[:target].armies ])
        @person.post_maybe_delayed(@game, message, params[:player] != player)
      when :move
        @person.post_map(@game) if params[:player] == player
        message = "%s:\n  %s flyttar %s fr�n %s till  %s.\n\n" % ([ @game.name,
                                                                    params[:to].owner.person.name,
                                                                    params[:armies].swedish_quantity('arm�', 'arm�er'),
                                                                    params[:from].name,
                                                                    params[:to].name ])
        message << "%23s: %2d - %2d = %2d\n%23s: %2d + %2d = %2d" % ([ params[:from].name,
                                                                       params[:from].armies + params[:armies],
                                                                       params[:armies],
                                                                       params[:from].armies,
                                                                       params[:to].name,
                                                                       params[:to].armies - params[:armies],
                                                                       params[:armies],
                                                                       params[:to].armies ])
        @person.post_maybe_delayed(@game, message, params[:player] != player)
      when :card
        if params[:to_player].person == @person
          @person.post('Du f�r ett kort: [%s]' % params[:to_player].last_card.to_s.upcase)
        else
          @person.post_maybe_delayed(@game, '%s f�r ett kort.' % params[:to_player].person.name)
        end
      else
        raise ArgumentError.new('Uknown GameObserver message')
      end
    end
    def stop
      @game.delete_observer(self)
    end
  end

  Commands = ({ ['nytt', 'parti'] => :new_game,
                ['deltag', 'i'] => :join,
                ['g�', 'till'] => :go_to,
                ['l�mna'] => :leave,
                ['inst�llningar'] => :settings,
                ['s�tt'] => :set,
                ['b�rja'] => :ready,
                ['s�g'] => :say,
                ['kapitulera'] => :surrender,
                ['placera'] => :place,
                ['klar'] => :done,
                ['anfall'] => :attack,
                ['flytta'] => :move,
                ['kort'] => :cards,
                ['karta'] => :map,
                ['administrera', 'starta'] => :start,
                ['administrera', 'stoppa'] => :stop,
                ['administrera', 'skjut', 'upp', 'deadlines'] => :push_deadlines,
                ['pratig'] => :verbose,
                ['var', 'pratig'] => :verbose,
                ['smygig'] => :quiet,
                ['var', 'smygig'] => :quiet,
                ['resum�'] => :history,
                ['resume'] => :history,
                ['svordom'] => :unimplemented,
                ['surfa'] => :svg_static,

                ['elisphack'] => :elisphack,
                ['status'] => :status,
                ['partier'] => :status,
                ['gr�nser'] => :borders,
              })

  PhaseNames = ['placera arm�er eller anv�nda kort', 'anfalla', 'flytta', 'avsluta din tur']
  PhasePastNames = [nil, 'anfallit', 'flyttat']

  def command(cmd)
    words = cmd.scan(/[,;!=]+|[^[:space:],;!=]+/)
    return if words.empty?

    alts = Commands.prefix_words_matches(words)
    begin
      if alts.empty?
        help
      elsif alts.length > 1
        raise AlternativesError.new(alts, words)
      elsif Commands[alts[0].first] == :say
        raw = cmd.gsub(/^\s*[^[:space:][:punct:]]+\s*/, '')
        say(raw)
      else
        send(Commands[alts[0].first], alts[0].last)
      end
    rescue NoCurrentGameException
      post 'Du �r inte aktiv i n�got parti!'
    rescue CommandError => e
      post e.message
    rescue Game::NotInTurnException
      post 'Du f�r v�nta p� din tur!'
    rescue Game::TurnPhaseException => e
      if e.params[:from] == 0
        post 'Du f�r inte %s, f�r du �r inte klar med dina placeringar!' % [ PhaseNames[e.params[:to]] ]
      else
        post 'Du f�r inte %s, f�r du har redan %s!' % [ PhaseNames[e.params[:to]], PhasePastNames[e.params[:from]] ]
      end
    rescue Game::NotCountryOwnerException => e
      post 'Du �ger inte %s!' % e.params[:country].name
    rescue Game::CountryOwnerException => e
      post 'Du �ger %s!' % e.params[:country].name
    rescue Game::BorderingException
      post 'L�nderna gr�nsar inte till varandra!'
    end
  end

  def help(words = nil)
    text = "Jag leder partier av ett spel inte helt olikt Risk.\n\nFraser jag potentiellt begriper:\n"
    phrases = ([ "partier",
                 "nytt parti [SPEL]",
                 "deltag i [SPEL]",
                 "b�rja",
                 "kort ...",
                 "placera ...",
                 "anfall ...",
                 "flytta ...",
                 "klar",
                 "l�mna [SPEL]",
                 "kapitulera",
                 "karta [SPEL]",
                 "gr�nser",
                 "s�g TEXT",
                 "elisphack",
                 "g� till [SPEL]",
                 "inst�llningar",
                 "s�tt NAMN [= V�RDE]",
                 "var smygig",
                 "var pratig",
                 "resum� [i brev]" ]).sort
    text << phrases.column_list_view
    text << "\nNamn och fraser g�r att kom-f�rkorta varhelst man vill."
    text << "\n\nFramf�r klagom�l till <person 9023: Nicklas Lindgren (�ter mopeder, �ppnar kasino)>\n\nGurk. Ost."
    post text
  end

  def push_deadlines(words = [])
    request(:type => :push_deadlines, :time => 3600 * 12)
  end

  def join_impl(game, notification = true)
    request(:game => game, :type => :join)
    @games[game] = GameObserver.new(self, game)
    post 'Du har g�tt med i %s.' % game.name if notification
    post settings_text(game)
    post players_text(game) if notification
    go_to_impl(game)
  end

  def new_game(words = [])
    game = request(:type => :new_game, :name => words.join(' '))
    post 'Du har skapat %s.' % game.name
    join_impl(game, false)
  rescue TooManyGamesException
    post 'Du f�r inte skapa fler spel!'
  end

  def join(words = [])
    open_games = $state.open_games.reject{ |g| @games.keys.include?(g) }
    if open_games.empty?
      post 'Det finns inga �ppna partier som du inte �r med i!'
    else
      game = open_games.pick_from(words, '�ppna partier')
      join_impl(game)
    end
  rescue Game::FullGameException
    post '%s �r fullt!' % game.name
  end

  def current_game!
    if not @current_game
      raise NoCurrentGameException.new
    else
      @current_game
    end
  end

  def go_to_impl(game)
    @current_game = game
    post 'Du �r nu aktiv i %s.' % @current_game.name
  end

  def go_to(words = [])
    games = @games.keys.reject{ |g| g == @current_game }
    if games.empty?
      if @current_game
        post 'Du deltar bara i ett parti!'
      else
        post 'Du deltar inte i n�gra partier!'
      end
    else
      game = games.pick_from(words, 'partier du deltar i')
      go_to_impl(game)
    end
  end

  def after_leave_impl(game)
    @games[game].stop
    @games.delete(game)
  end

  def game_from_words(words)
    if words.empty?
      current_game!
    else
      @games.keys.pick_from(words, 'partier du deltar i')
    end
  end

  def leave(words = [])
    game = game_from_words(words)
    request(:game => game, :type => :leave)
    after_leave_impl(game)
    #post 'Du har l�mnat %s.' % game.name
    @current_game = nil
  rescue Game::AlreadyStartedException
    post 'Spelet har redan b�rjat. Du f�r kapitulera ist�llet.'
  end

  def say(text)
    if text.empty?
      post 'Vad vill du s�ga?'
    else
      request(:game => current_game!, :type => :say, :text => text)
    end
  end

  def settings_text(game)
    message = "Inst�llningar f�r %s\n" % game.name
    message << game.settings.collect do |key, setting|
      '  %s: %s' % [ setting.name, setting.to_s ]
    end.join("\n")
    return message
  end

  def setting_text(setting)
    message = "%s - %s\n  V�rde: %s\n  Giltiga v�rden: " % [ setting.name, setting.description, setting.to_s ]
    if setting.respond_to?(:choices)
      message << setting.choices.collect{ |c| c.name }.swedish
    else
      message << 'Heltal'
    end
    return message
  end

  def players_text(game)
    message = "Deltagare i %s\n" % game.name
    message << game.players.collect do |player|
      '  %s' % player.name
    end.join("\n")
    return message
  end

  def settings(words = [])
    game = game_from_words(words)
    post settings_text(game)
  end

  def set(words = [])
    if words.empty?
      settings
    else
      setting, rest = current_game!.settings.values.pick_from_with_rest(words, 'inst�llningar')
      if rest.empty?
        post setting_text(setting)
      else
        if rest[0] != '='
          post 'Det b�r vara ett "=" d�r n�gonstans.'
        else
          if setting.respond_to?(:choices)
            new_value = setting.choices.pick_from(rest[1..-1], 'alternativ')
          else
            new_value = rest[1..-1].join.to_i
          end
          request(:game => @current_game, :type => :set, :setting => setting, :value => new_value)
        end
      end
    end
  rescue Game::AlreadyStartedException
    post 'Spelet har redan b�rjat!'
  end

  def ready(words = [])
    request(:game => current_game!, :type => :ready)
  rescue Game::AlreadyStartedException
    post 'Spelet har redan b�rjat!'
  rescue Game::TooFewPlayersException
    if @current_game.players.length == 1
      post 'Det kr�vs mer �n en spelare f�r att b�rja partiet!'
    elsif @current_game.players.length < 3 and @current_game.settings[:gametype].value == :mission
      post 'Det kr�vs minst tre spelare f�r speltypen Hemligt Uppdrag!'
    end
  end

  def surrender(words = [])
    if words != ['!']
      post '�r du s�ker? Anv�nd i s� fall utropstecken.'
    else
      request(:game => current_game!, :type => :surrender)
    end
  end

  def placement_parse(words = [], accumulated = [])
    return accumulated if words.empty?
    case words.first
    when /^(,|och)$/
      return placement_parse(words[1..-1], accumulated)
    when /^-?[0-9]+$/
      armies = words.first.to_i
      return country_parse(armies, words[1..-1], accumulated)
    else
      countries = @current_game.people_players[self].countries
      country, rest = countries.pick_from_with_rest(words, 'l�nder du �ger')
      return armies_parse(country, rest, accumulated)
    end
  end

  def armies_parse(country, words, accumulated)
    raise CommandError.new('Kommandot slutade d� jag v�ntade mig ett antal arm�er!') if words.empty?
    case words.first
    when '='
      return armies_parse(country, words[1..-1], accumulated)
    else
      armies = words.first.to_i
      return placement_parse(words[1..-1], accumulated.push([country, armies]))
    end
  end

  def country_parse(armies, words, accumulated)
    raise CommandError.new('Kommandot slutade d� jag v�ntade mig ett land!') if words.empty?
    case words.first
    when 'i'
      return country_parse(armies, words[1..-1], accumulated)
    else
      countries = @current_game.people_players[self].countries
      country, rest = countries.pick_from_with_rest(words, 'l�nder du �ger')
      return placement_parse(rest, accumulated.push([country, armies]))
    end
  end

  def place(words = [])
    if words.empty?
      post "Anv�ndningsexempel:\n    placera 3 i Indien, -1 i Irkutsk\n    pl 3 indi -1 irk\n    pl indi 3 irk -1"
    else
      current_game!
      placements, exceptions = request(:game => @current_game, :type => :place, :placement => placement_parse(words))
      exceptions.each do |e|
        begin
          raise e
        rescue Game::TooFewArmiesException => e
          post 'F�r f� arm�er i %s!' % e.params[:country].name
        rescue Game::TooManyArmiesException => e
          post 'F�r m�nga arm�er i %s! Varje land f�r b�rja med max fyra arm�er.' % e.params[:country].name
        end
      end
      if not placements.empty?
        post_map(@current_game)
        response = "Du har placerat ut f�ljande arm�er:\n"
        response += placements.collect do |country, armies|
          if armies > 0
            '%23s %2d + %2d = %2d' % [ country.name, country.total_armies - armies, armies, country.total_armies ]
          else
            '%23s %2d - %2d = %2d' % [ country.name, country.total_armies - armies, -armies, country.total_armies ]
          end
        end.join("\n")
        post response
      end
      if @current_game.people_players[self].armies_for_placement == 0
        if @current_game.first_placement_done
          post '�r du klar kan du g�ra "anfall". Vill du inte anfalla kan du b�rja direkt med att "flytta". Vill du ingetdera kan du s�ga "klar".'
        else
          post 'S�g "klar" om du �r n�jd med placeringen av dina arm�er.'
        end
      elsif @current_game.people_players[self].armies_for_placement > 0
        post 'Du har %s kvar att placera ut.' % @current_game.people_players[self].armies_for_placement.swedish_quantity('arm�', 'arm�er')
      else
        post 'Du har placerat ut %s mer �n till�tet. �tg�rda!' % (-@current_game.people_players[self].armies_for_placement).swedish_quantity('arm�', 'arm�er')
      end
    end
  end

  def done(words = [])
    current_game!
    if not @hasty_done_warning and @current_game.first_placement_done and @current_game.in_turn(self) and
        @current_game.turn_phase == 0 and @current_game.turn_queue.first.armies_for_placement == 0
      @hasty_done_warning = true
      post 'Varning: "klar" avslutar din tur. �r du s�ker p� att du inte vill "anfalla" eller "flytta"? Den h�r varningen upprepas inte.'
    else
      request(:game => @current_game, :type => :done)
    end
  end

  def attack(words = [])
    if words.empty?
      post "Synopsis:\n    anfall LAND [ fr�n LAND ] [ med ARM�ER ] [!]\n    anfall igen"
    else
      current_game!
      countries = @current_game.people_players[self].countries.select{ |c| c.total_armies > 1 }
      attackable_countries = @current_game.people_players[self].attackable_countries
      if words.first =~ /^(igen|ige|ig)$/
        if not @last_attack
          post 'Du har inte anfallit �nnu den h�r omg�ngen!'
        else
          target = @last_attack[:target]
          from = @last_attack[:from]
          armies = @last_attack[:armies]
          destroy = @last_attack[:destroy]
        end
      else
        target, rest = attackable_countries.pick_from_with_rest(words, 'l�nder du kan anfalla')
        if @last_attack and @last_attack[:target] == target
          from = @last_attack[:from]
          armies = @last_attack[:armies]
          destroy = @last_attack[:destroy]
        else
          from = nil
          armies = nil
          destroy = false
        end
        if rest.first =~ /^(fr�n|fr�|fr|f)$/
          from, rest = countries.pick_from_with_rest(rest[1..-1], 'l�nder att anfalla fr�n')
        end
        if rest.first =~ /^(med|me|m)$/
          armies = rest[1].to_i
          rest = rest[2..-1]
        end
        if rest.first == '!'
          destroy = true
          rest = rest[1..-1]
        end
      end
      if rest and not rest.empty?
        post 'Avslutande obegripligheter: "%s"' % [ rest.join(' ')]
      elsif not from
        post 'Det �r oklart vilket land du vill anfalla fr�n.'
      elsif not armies
        post 'Det �r oklart hur m�nga arm�er du vill anfalla med.'
      else
        @last_attack = { :target => target, :from => from, :armies => armies, :destroy => destroy }
        @last_attack[:armies] = request({:game => @current_game, :type => :attack}.merge(@last_attack))
      end
    end
  rescue Game::TooFewArmiesException
    post 'Det �r ett f�nigt antal arm�er att anfalla med.'
  rescue Game::TooManyArmiesException
    post 'Du har inte s� m�nga arm�er tillg�ngliga f�r ett anfall!'
  end

  def move(words = [])
    if words.empty?
      post "Synopsis:\n    flytta ARM�ER [ fr�n LAND ] [ till LAND ]"
    else
      countries = current_game!.people_players[self].countries
      to = nil
      from = nil
      armies = words.first.to_i
      rest = words[1..-1]
      loop do
        if rest.first =~ /^(fr�n|fr�|fr|f)$/
          from, rest = (to ? to.borders : countries).pick_from_with_rest(rest[1..-1], 'l�nder')
        elsif rest.first =~ /^(till|til|ti|t)$/
          to, rest = (from ? from.borders : countries).pick_from_with_rest(rest[1..-1], 'l�nder')
        else
          break
        end
      end
      if @last_move
        from ||= @last_move[:from]
        to ||= @last_move[:to]
      end
      if not rest.empty?
        post 'Avslutande obegripligheter: "%s"' % rest.join(' ')
      elsif not from
        post 'Det �r oklart vilket land du vill flytta fr�n.'
      elsif not to
        post 'Det �r oklart vilket land du vill flytta till.'
      else
        @last_move = { :to => to, :from => from, :armies => armies }
        request({:game => @current_game, :type => :move}.merge(@last_move))
      end
    end
  rescue Game::TooFewArmiesException
    post 'Det �r ett f�nigt antal arm�er att flytta.'
  rescue Game::TooManyArmiesException
    post 'Du f�r inte flytta s� m�nga arm�er d�rifr�n!'
  rescue Game::MovesExhaustedException
    post 'Du f�r inte flytta s� m�nga arm�er!'
  end

  def post_mission(mission)
    post("Ditt uppdrag �r: %s\n\nDu vinner om villkoren �r eller blir uppfyllda under din tur." % mission.swedish)
  end

  def cards(words = [])
    if words.empty?
      post "Anv�ndningsexempel:\n    kort a a a\n    kort a b c\n    kort c c *\n\n3xA ger fyra arm�er, 3xB ger sex, 3xC ger �tta. En av varje ger tio. * fungerar som joker."
      if @current_game
        cards = @current_game.people_players[self].cards
        if cards.empty?
          post 'Du har inga kort i %s.' % @current_game.name
        else
          post 'Du har f�ljande kort i %s: %s' % [ @current_game.name, cards_str(cards) ]
        end
        if @current_game.settings[:gametype].value == :mission
          post_mission(@current_game.people_players[self].mission)
        end
      end
    else
      cards = { :a => 0, :b => 0, :c => 0, :* => 0 }
      words.each do |w|
        card = w.downcase.to_sym
        if cards.has_key?(card)
          cards[card] += 1
        else
          post 'Felaktig korttyp: "%s"' % w
          return
        end
      end
      request(:game => @current_game, :type => :cards, :cards => cards)
    end
  rescue Game::IllegalCardComboException
    post 'Det �r inte en giltig kortkombination!'
  rescue Game::InsuficcentCardsException
    post 'Du har inte alla dom korten!'
  end

  def map(words = [])
    if words.first =~ /^(namn|nam|na)$/
      post map_str(current_game!.map, true)
    elsif words.empty?
      post map_str(current_game!.map)
    else
      post map_str($state.games.pick_from(words, 'partier').map)
    end
  end

  def status(words = nil)
    if @current_game
      post 'Du �r aktiv i %s.' % @current_game.name
    else
      post 'Du �r inte aktiv i n�got parti.'
    end
    games = @games.keys.reject{ |g| g == @current_game }
    if not games.empty?
      post "Du deltar%s i:\n%s" % [ (@current_game ? ' ocks�' : ''), games.collect{ |g| game_str(g) }.join("\n") ]
    end
    if @games.empty? and $state.open_games.empty?
      post 'Det finns inga �ppna partier just nu. Skriv "nytt parti" om du vill skapa ett.'
    end
    [ [ $state.open_games, '�ppna spel' ],
      [ $state.running_games, 'P�g�ende spel' ],
      [ $state.finished_games.reverse[0..2], 'Nyligen avslutade spel' ] ].each do |games, caption|
      if games and not games.empty?
        post "%s:\n%s" % [ caption, games.collect{ |g| game_str(g) }.join("\n") ]
      end
    end
  end

  def unimplemented(words = nil)
    post "Just nu f�rst�r jag inte vad du menar. Men det blir nog b�ttre med tiden."
  end

  def verbose(words = nil)
    @quiet = false
    post 'Nu f�r du meddelanden s� fort n�got h�nder i ett parti d�r du deltar! S�g "var smygig" om du vill �ndra det.'
  end

  def quiet(words = nil)
    @quiet = true
    post 'Nu f�r du bara meddelanden i partier d�r det �r din tur. S�g "var pratig" om du vill �ndra det.'
  end

  def history(words = [])
    unless words.empty?
      post 'F�r n�rvarande kan du bara f� en resum� som personligt meddelande.'
    else
      if has_delayed?(current_game!)
        flush_delayed(current_game!)
      else
        post 'Ingenting har h�nt i %s som du inte h�rt om.' % @current_game.name
        unless @quiet
          post 'Den h�r finessen kan vara an�ndbar om du har sagt "var smygig".'
        end
      end
    end
  end

  def borders(words = nil)
    result = ''
    current_game!.map.continents.each do |continent|
      result << "--- %s (%s, %s)\n" % [ continent.name,
                                        continent.countries.length.swedish_quantity('land', 'l�nder', :neutrum => true),
                                        continent.bonus_armies.swedish_quantity('bonusarm�', 'bonusarm�er') ]
      continent.countries.each do |country|
        result << "  %23s: %s\n" % [ country.name,
                                           country.borders.collect{ |b| b.name }.swedish ]
      end
      result << "\n"
    end
    post result
  end

  def svg_static(words = nil)
    hash = current_game!.map.countries.collect do |c|
      '%d,%d' % [c.owner ? c.owner.number : 6, c.armies]
    end.join(';')
    post 'Surfa till: %sstatic.svg#s%s' % [ $WEB_SETTINGS[:base_url], hash ]
  end

  def elisphack(words = nil)
    text = "Praktiska saker f�r elisp-klienten:\n\n"
    text << ';;; Bind s g till att s�nda ett meddelande till mig:
  (defun generalen-keybinding ()
    (local-set-key [?s ?g] (lambda nil (interactive)
  			   (set-buffer "%s")
  			   (kom-send-message %d)
  			   (switch-to-buffer "%s"))))

  (add-hook \'lyskom-mode-hook #\'generalen-keybinding)

;;; F�r dom v�gade: ett fulhack som visar f�rgade kartor.
;;; Byter buffer. �r f�rmodligen irriterande i vissa l�gen.
  (defgroup generalen \'() "F�rgl�ggningsfulhack")
  (defface generalen-map
    \'((t (:background "darkslateblue" :foreground "white")))
    "Grundl�ggande face som �rvs av, och som anv�nds p� kartan d�r inget annat passar"
    :group \'generalen)
  (defface generalen-water
    \'((t (:inherit generalen-map :foreground "slateblue" :weight bold)))
    "Vatten"
    :group \'generalen)
  (defface generalen-border
    \'((t (:inherit generalen-map :foreground "white")))
    "Gr�nser"
    :group \'generalen)
  (defface generalen-player-1
    \'((t (:inherit generalen-map :foreground "#a0a8ff" :weight bold)))
    "Spelaren med tecknet #"
    :group \'generalen)
  (defface generalen-player-2
    \'((t (:inherit generalen-map :foreground "red" :weight bold)))
    "Spelaren med tecknet X"
    :group \'generalen)
  (defface generalen-player-3
    \'((t (:inherit generalen-map :foreground "green2" :weight bold)))
    "Spelaren med tecknet O"
    :group \'generalen)
  (defface generalen-player-4
    \'((t (:inherit generalen-map :foreground "yellow" :weight bold)))
    "Spelaren med tecknet %%"
    :group \'generalen)
  (defface generalen-player-5
    \'((t (:inherit generalen-map :foreground "magenta" :weight bold)))
    "Spelaren med tecknet @"
    :group \'generalen)
  (defface generalen-player-6
    \'((t (:inherit generalen-map :foreground "#d08000" :weight bold)))
    "Spelaren med tecknet �"
    :group \'generalen)

  (defmacro generalen-reformat (regexp face)
    `(let (pos (start map-start))
       (while (setq pos (string-match ,regexp message start))
         (setq start (match-end 0))
         (when (< pos map-end) (add-text-properties pos start \'(face ,face) message)))))

  (add-hook \'lyskom-mode-hook #\'generalen-keybinding)
  (defun generalen-reformat-map (message)
    (remove-text-properties 0 (length message) \'(face \'foo) message)
    (let ((map-start nil) (map-end nil))
      (string-match "\\\\(.\\\\|\\n\\\\)*~\\n" message)
      (setq map-end (match-end 0))
      (setq map-start 0)
      (generalen-reformat ".+" generalen-map)
      (generalen-reformat "~+" generalen-water)
      (generalen-reformat "[/_\\\\\\\\]+" generalen-border)
      (generalen-reformat "# ?[0-9?]+" generalen-player-1)
      (generalen-reformat "X ?[0-9?]+" generalen-player-2)
      (generalen-reformat "O ?[0-9?]+" generalen-player-3)
      (generalen-reformat "%% ?[0-9?]+" generalen-player-4)
      (generalen-reformat "@ ?[0-9?]+" generalen-player-5)
      (generalen-reformat "� ?[0-9?]+" generalen-player-6)
      (setq map-start map-end)
      (setq map-end (string-match " L�nder \\\\[" message))
      (when map-end
        (generalen-reformat "^  (.)[^[\\n]*" bold)
        (generalen-reformat "(#)" generalen-player-1)
        (generalen-reformat "(X)" generalen-player-2)
        (generalen-reformat "(O)" generalen-player-3)
        (generalen-reformat "(%%)" generalen-player-4)
        (generalen-reformat "(@)" generalen-player-5)
        (generalen-reformat "(�)" generalen-player-6)
        (setq map-start map-end)
        (setq map-end (+ 1 (string-match "\\\\]" message (string-match "Plus" message map-start))))
        (generalen-reformat "#+" generalen-player-1)
        (generalen-reformat "X+" generalen-player-2)
        (generalen-reformat "O+" generalen-player-3)
        (generalen-reformat "%%+" generalen-player-4)
        (generalen-reformat "@+" generalen-player-5)
        (generalen-reformat "�+" generalen-player-6)
        (generalen-reformat "\\\\[\\\\|\\\\]\\\\|-+" generalen-water))))

  (defun generalen-personal-message ()
    (when (and (eq %d (conf-stat->conf-no sender)) (string-match "^~" message))
      (set-buffer (get-buffer-create "*generalen*"))
      (generalen-keybinding)
      (let ((old-point (point-max)))
        (goto-char old-point)
        (generalen-reformat-map message)
        (insert message)
        (insert "\\n\\n")
        (switch-to-buffer "*generalen*")
        (goto-char old-point)
        (recenter 0))))

  (add-hook \'kom-personal-message-hook #\'generalen-personal-message)

' % [ $KOM_SETTINGS[:server],
      $KOM_SETTINGS[:person],
      $KOM_SETTINGS[:server],
      $KOM_SETTINGS[:person] ]
    post text
  end
end
