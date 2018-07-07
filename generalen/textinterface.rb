# coding: utf-8
#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++

require_relative '../util/view'
require_relative '../util/swedish'
require_relative '../generalen/game'

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

class MapString
  attr_accessor :map_string, :map_url, :text, :title, :title_url
  def to_s
    @map_string + @text
  end
  def attachments
    [
      {
        fallback: "```#{@map_string}```",
        image_url: @map_url,
        title: @title,
        title_link: @title_url,
      }
    ]
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
        @alts = "Vilket av följande %s menar du?\n%s" % [ name,  alts.collect{ |a| a.first.join(' ') }.sort.column_list_view ]
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

  INITIALS = ['#', 'X', 'O', '%', '@', '¤']

  def map_str(map, names=false)
    if map.name != :standard
      raise ArgumentError.new('Okänd karttyp')
    else
      if names
        map_string = MapString.new
        result = STANDARD_MAP % map.countries.collect do |c|
          words = c.name.split
          if words.length ==1
            words.first[0..2]
          else
            '%s %s' % [ words[0][0..0], words[1][0..0] ]
          end
        end
        map_string.map_string = result
        map_string.map_url = 'https://maps.gurkmoj.net/v0/'
        map_string.title = 'Karta'
        map_string.title_url = 'https://maps.gurkmoj.net/v0/L/'
        return map_string
      else
        map_string = MapString.new
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
        map_string.map_string = result
        args = map.countries.collect do |c|
          (c.owner ? c.owner.number + 1 : 0) +
            if c.owner && c.owner.person != self and not map.game.first_placement_done
              0
            elsif c.owner && c.owner.person != self
              c.armies * 7
            else
              c.total_armies * 7
            end
          end.join(",")
        map_string.map_url = "https://maps.gurkmoj.net/v0/#{args}"
        title = map.game.name + (map.game.round > 0 ? ', omgång %d' % map.game.round : '')
        map_string.title = title
        map_string.title_url = "https://maps.gurkmoj.net/v0/L/#{args}"
        result = "  %s%s%s\n" % [ title, deadline_str(map.game), progressive_cards_str(map.game) ]
        map.game.initial_turn_order.each do |player|
          result << "  (%s) %s%s\n" % ([ INITIALS[player.number],
                                         player.name,
                                         player_info_str(player, player.person == self) ])
          if map.game.show_stats? or not map.game.active
            result << "    %s, %s%s (%s)\n" % ([ cards_str(player.cards, !player.game.finished),
                                                 player.countries.length.swedish_quantity('land', 'länder', :neutrum => true),
                                                 continents_str(player.continents),
                                                 armies_str(player) ])
          else
            result << "    %s%s\n" % ([ cards_str(player.cards, !player.game.finished),
                                        brief_continents_str(player.continents) ])
          end
          if player.mission and not map.game.active
            result << "    Uppdrag: %s\n" % player.mission.swedish
          end
        end
        if map.game.started and map.game.show_stats?
          country_distribution = map.game.initial_turn_order.collect{ |p| [INITIALS[p.number], p.countries.length] }
          army_distribution = map.game.initial_turn_order.collect{ |p| [INITIALS[p.number], p.armies] }
          plus_distribution = map.game.initial_turn_order.collect{ |p| [INITIALS[p.number], p.bonus_armies] }
          total_pluses = map.countries.length / 3 + map.continents.inject(0){ |acc, c| acc + c.bonus_armies }
          remaining = total_pluses - plus_distribution.inject(0){ |acc, p| acc + p.last }
          plus_distribution << ['-', remaining]

          result << ' '*9 + (['.']*5).join(' '*16) + "\n"
          result << " Länder [%s]\n" % distribution_graph(country_distribution, 69)
          result << " Arméer [%s]\n" % distribution_graph(army_distribution, 69)
          result << '   Plus [%s]' % distribution_graph(plus_distribution, 69)
        end
        map_string.text = result
        return map_string
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
    if player.game.in_turn(player) and player.game.first_placement_done and not player.game.finished
      result << ' [I tur]'
      return result if short
      parts = []
      if player.game.turn_phase == 0
        if current
          parts << '%d att placera' % player.armies_for_placement if player.armies_for_placement != 0
        elsif player.game.placements_allowed
          parts << '%d att placera' % player.bonus_armies
        end
      end
      if player.armies_for_movement != 0
        parts << '%d att flytta' % player.armies_for_movement
      end
      result << ' [%s]' % parts.join(', ') unless parts.empty?
    elsif not player.game.first_placement_done and player.game.in_turn(player)
      if current
        result << ' [%d att placera]' % player.armies_for_placement
      else
        result << ' [Ska placera arméer]'
      end
    end
    if player.game.open and player.ready
      result << ' [Redo att börja]'
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

  def progressive_cards_str(game)
    if game.progressive_cards? && game.started
      ' [Kort ger %s]' % game.progressive_card_value.swedish_quantity('armé', 'arméer')
    else
      ''
    end
  end

  def continents_str(continents)
    if continents.empty?
      ''
    else
      ' inklusive hela %s' % continents.collect{ |c| c.name }.swedish
    end
  end

  def brief_continents_str(continents)
    if continents.empty?
      ''
    else
      ', hela %s' % continents.collect{ |c| c.name }.swedish
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
            @person.post('Du måste gå till %s och skriva "börja" igen om du är redo.' % @game.name)
          else
            @person.post('Du måste skriva "börja" igen om du är redo.')
          end
        else
          if @person.current_game != game
            @person.post('Gå till %s och skriv "börja" om du är redo att börja partiet.' % @game.name)
          else
            @person.post('Skriv "börja" om du är redo att börja partiet.')
          end
        end
      end
    end
    def maybe_prompt_for_history
      if @person.has_delayed?(@game)
        @person.post 'Skriv "resumé" om du vill veta vad som hänt.'
      end
    end
    def maybe_auto_switch_game
      in_turn_game = @person.games.values.detect{ |g| g.game.person_in_turn(@person) }
      if in_turn_game
        games = @person.games.values.select{ |g| g.game.person_in_turn(@person) }
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
        @person.current_game != @game and not @person.current_game.person_in_turn(@person)
      else
        true
      end
    end
    def update(type, params = {})
      case type
      when :join
        @person.post('%s har gått med i %s.' % [ params[:person].name, @game.name ])
        maybe_request_ready
      when :leave
        @person.post('%s har lämnat %s.' % [ params[:person].name, @game.name ])
        maybe_request_ready
      when :ceased
        if not @end_announced
          @person.post('%s har upphört.' % [ @game.name ])
          @end_announced = true
        end
      when :set
        @person.post('%s har satt %s till %s i %s.' % [ params[:by_person].name, params[:setting].name, params[:setting], @game.name ])
        maybe_request_ready
      when :ready
        @person.post('%s är redo att börja i %s.' % [ params[:person].name, @game.name ])
        if params[:person] == @person
          @has_been_ready = true
          @ready = true
        end
        if not params[:not_ready].empty?
          waiting_message = "Väntar på följande spelare:\n"
          waiting_message << params[:not_ready].collect{ |n| '  '+n.name }.join("\n")
          @person.post(waiting_message)
        end
      when :done
        @person.post('%s är klar med sina första utplaceringar i %s.' % [ params[:person].name, @game.name ])
        if not params[:not_done].empty?
          waiting_message = "Väntar på följande spelare:\n"
          waiting_message << params[:not_done].collect{ |n| '  '+n.name }.join("\n")
          @person.post(waiting_message)
        end
        if params[:person] == @person
          maybe_auto_switch_game
        end
      when :nobody_ready
        @ready = false
      when :started
        @person.post('%s har börjat!' % @game.name)
        order_message = "Turordningen slumpas till:\n"
        order_message << @game.turn_queue.select{ |n| n != :new_round }.collect{ |n| '  '+n.name }.join("\n")
        @person.post(order_message)
        if player.mission
          @person.post_mission(player.mission)
        end
        countries = player.countries
        @person.post("Du tilldelas %s: %s.\n\nDu har %s att placera ut." % ([ countries.length.swedish_quantity('land', 'länder', :neutrum => true),
                                                                              countries.collect{ |c| c.name }.sort.swedish,
                                                                              player.armies_for_placement.swedish_quantity('armé', 'arméer') ]))
        if may_auto_change_game?
          @person.go_to_impl(@game)
        end
      when :surrender
        @person.post('--- %s har kapitulerat i %s! ---' % [ params[:person].name, @game.name ])
      when :defeated
        @person.post('--- %s är besegrad i %s! ---' % [ params[:person].name, @game.name ])
        if params[:n_cards] and params[:n_cards] > 0
          if params[:by_person] == @person
            @person.post('Du övertar följande kort: %s' % @person.cards_str(params[:cards]))
          else
            @person.post('%s övertar %s.' % [ params[:by_person].name, params[:n_cards].swedish_quantity('kort', 'kort', :neutrum => true) ])
          end
        end
      when :winner
        @person.post('--- %s har vunnit %s! ---' % [ params[:person].name, @game.name ])
        maybe_prompt_for_history
        @end_announced = true
      when :say
        @person.post("%s [%s]:\n%s" % [ params[:person].name, @game.name, params[:text] ])
      when :turn_timeout
        @person.post('Tiden är ute för %s i %s!' % ([ (@game.first_placement_done ? @game.turn_queue.first.name : 'placering'),
                                                      @game.name ]))
      when :turn_change
        if params[:to_person] == @person
          @person.post_map(@game)
          @person.post('*** Det är din tur i %s! ***' % @game.name)
          maybe_prompt_for_history
          @last_attack = nil
          @last_move = nil
          if player.armies_for_placement > 0
            @person.post('Du har %s nya arméer att placera ut.' % player.armies_for_placement.swedish_quantity('ny armé', 'nya arméer'))
          else
            @person.post('Du får inga arméer första rundan, men du kan "anfalla", sedan "flytta" eller anse dig vara "klar".' % player.armies_for_placement)
          end
          if player.total_cards >= 5
            @person.post('Du måste använda en uppsättning kort den här omgången.')
          end
          if may_auto_change_game?
            @person.go_to_impl(@game)
          end
        else
          message = 'Turen övergår till %s i %s.' % [ params[:to_person].name, @game.name ]
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
        message = "%s:\n%s får %s för följande kort: %s" % ([ @game.name,
                                                              params[:person].name,
                                                              params[:armies].swedish_quantity('extra armé', 'extra arméer'),
                                                              @person.cards_str(params[:cards]) ])
        @person.post_maybe_delayed(@game, message, params[:player] != player)
      when :place
        if not params[:placements].empty?
          @person.post_map(@game) if params[:player] == player
          message = "%s:\n  %s placerar ut följande arméer:\n" % [ @game.name, params[:person].name ]
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
        message << "   Anfall: %-11s   %23s: %2d - %2d = %2d\n  Försvar: %-11s   %23s: %2d - %2d = %2d" %
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
        message = "%s erövrar %s!\n\n" % [ params[:target].owner.person.name, params[:target].name ]
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
        message = "%s:\n  %s flyttar %s från %s till %s.\n\n" % ([ @game.name,
                                                                   params[:to].owner.person.name,
                                                                   params[:armies].swedish_quantity('armé', 'arméer'),
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
          @person.post('Du får ett kort: [%s]' % params[:to_player].last_card.to_s.upcase)
        else
          @person.post_maybe_delayed(@game, '%s får ett kort.' % params[:to_player].person.name)
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
                ['gå', 'till'] => :go_to,
                ['lämna'] => :leave,
                ['inställningar'] => :settings,
                ['sätt'] => :set,
                ['börja'] => :ready,
                ['säg'] => :say,
                ['kapitulera'] => :surrender,
                ['placera'] => :place,
                ['klar'] => :done,
                ['anfall'] => :attack,
                ['flytta'] => :move,
                ['kort'] => :cards,
                ['byt', 'in'] => :use_cards,
                ['karta'] => :map,
                ['administrera', 'starta'] => :start,
                ['administrera', 'stoppa'] => :stop,
                ['administrera', 'skjut', 'upp', 'deadlines'] => :push_deadlines,
                ['pratig'] => :verbose,
                ['var', 'pratig'] => :verbose,
                ['smygig'] => :quiet,
                ['var', 'smygig'] => :quiet,
                ['resumé'] => :history,
                ['resume'] => :history,
                ['svordom'] => :unimplemented,
                ['surfa'] => :svg_static,
                ['uppdrag'] => :mission,

                ['status'] => :status,
                ['partier'] => :status,
                ['gränser'] => :borders,
              })

  if $KOM_SETTINGS
    Commands[['elisphack']] = :elisphack
  end


  PhaseNames = ['placera arméer eller använda kort', 'anfalla', 'flytta', 'avsluta din tur']
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
      post 'Du är inte aktiv i något parti!'
    rescue CommandError => e
      post e.message
    rescue Game::NotInTurnException
      post 'Du får vänta på din tur!'
    rescue Game::GameNotStartedException
      post 'Spelet har inte startat än!'
    rescue Game::GameEndedException
      post 'Spelet är redan slut!'
    rescue Game::TurnPhaseException => e
      if e.params[:from] == 0
        post 'Du får inte %s, för du är inte klar med dina placeringar!' % [ PhaseNames[e.params[:to]] ]
      else
        post 'Du får inte %s, för du har redan %s!' % [ PhaseNames[e.params[:to]], PhasePastNames[e.params[:from]] ]
      end
    rescue Game::NotCountryOwnerException => e
      post 'Du äger inte %s!' % e.params[:country].name
    rescue Game::CountryOwnerException => e
      post 'Du äger %s!' % e.params[:country].name
    rescue Game::BorderingException
      post 'Länderna gränsar inte till varandra!'
    rescue Game::TooManyCardsException
      post "Du måste byta in kort den här omgången!\nDu får inte ha fler än fem kort."
    end
  end

  def help(words = nil)
    text = "(Sorry, i only speak swedish.)\n\nJag leder partier av ett spel inte helt olikt Risk.\n\nFraser jag potentiellt begriper:\n"
    phrases = ([ "partier",
                 "nytt parti [SPEL]",
                 "deltag i [SPEL]",
                 "börja",
                 "kort",
                 "byt in ...",
                 "placera ...",
                 "anfall ...",
                 "flytta ...",
                 "klar",
                 "lämna [SPEL]",
                 "kapitulera",
                 "karta [SPEL]",
                 "gränser",
                 "säg TEXT",
                 "gå till [SPEL]",
                 "inställningar",
                 "sätt NAMN [= VÄRDE]",
                 "var smygig",
                 "var pratig",
                 "resumé [i brev]",
                 "uppdrag" ])
    if $KOM_SETTINGS
      phrases << "elisphack"
    end
    phrases = phrases.sort
    text << phrases.column_list_view
    text << "\nNamn och fraser går att kom-förkorta varhelst man vill."
    text << "\n\nFramför klagomål till #{$settings[:admin]}"
    post text
  end

  def push_deadlines(words = [])
    request(:type => :push_deadlines, :time => 3600 * 12)
  end

  def join_impl(game, notification = true)
    request(:game => game, :type => :join)
    @games[game] = GameObserver.new(self, game)
    post 'Du har gått med i %s.' % game.name if notification
    post settings_text(game)
    post players_text(game) if notification
    go_to_impl(game)
  end

  def new_game(words = [])
    game = request(:type => :new_game, :name => words.join(' '))
    post 'Du har skapat %s.' % game.name
    join_impl(game, false)
  rescue TooManyGamesException
    post 'Du får inte skapa fler spel!'
  end

  def join(words = [])
    open_games = $state.open_games.reject{ |g| @games.keys.include?(g) }
    if open_games.empty?
      post 'Det finns inga öppna partier som du inte är med i!'
    else
      game = open_games.pick_from(words, 'öppna partier')
      join_impl(game)
    end
  rescue Game::FullGameException
    post '%s är fullt!' % game.name
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
    post 'Du är nu aktiv i %s.' % @current_game.name
  end

  def go_to(words = [])
    games = @games.keys.reject{ |g| g == @current_game }
    if games.empty?
      if @current_game
        post 'Du deltar bara i ett parti!'
      else
        post 'Du deltar inte i några partier!'
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
    #post 'Du har lämnat %s.' % game.name
    @current_game = nil
  rescue Game::AlreadyStartedException
    post 'Spelet har redan börjat. Du får kapitulera istället.'
  end

  def say(text)
    if text.empty?
      post 'Vad vill du säga?'
    else
      request(:game => current_game!, :type => :say, :text => text)
    end
  end

  def settings_text(game)
    message = "Inställningar för %s\n" % game.name
    message << game.settings.collect do |key, setting|
      '  %s: %s' % [ setting.name, setting.to_s ]
    end.join("\n")
    return message
  end

  def setting_text(setting)
    message = "%s - %s\n  Värde: %s\n  Giltiga värden: " % [ setting.name, setting.description, setting.to_s ]
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
      setting, rest = current_game!.settings.values.pick_from_with_rest(words, 'inställningar')
      if rest.empty?
        post setting_text(setting)
      else
        if rest[0] != '='
          post 'Det bör vara ett "=" där någonstans.'
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
    post 'Spelet har redan börjat!'
  end

  def ready(words = [])
    request(:game => current_game!, :type => :ready)
  rescue Game::AlreadyStartedException
    post 'Spelet har redan börjat!'
  rescue Game::TooFewPlayersException
    if @current_game.players.length == 1
      post 'Det krävs mer än en spelare för att börja partiet!'
    elsif @current_game.players.length < 3 and @current_game.settings[:gametype].value == :mission
      post 'Det krävs minst tre spelare för speltypen Hemligt Uppdrag!'
    end
  end

  def surrender(words = [])
    if words != ['!']
      post 'Är du säker? Använd i så fall utropstecken.'
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
      country, rest = countries.pick_from_with_rest(words, 'länder du äger')
      return armies_parse(country, rest, accumulated)
    end
  end

  def armies_parse(country, words, accumulated)
    raise CommandError.new('Kommandot slutade då jag väntade mig ett antal arméer!') if words.empty?
    case words.first
    when '='
      return armies_parse(country, words[1..-1], accumulated)
    else
      armies = words.first.to_i
      return placement_parse(words[1..-1], accumulated.push([country, armies]))
    end
  end

  def country_parse(armies, words, accumulated)
    raise CommandError.new('Kommandot slutade då jag väntade mig ett land!') if words.empty?
    case words.first
    when 'i'
      return country_parse(armies, words[1..-1], accumulated)
    else
      countries = @current_game.people_players[self].countries
      country, rest = countries.pick_from_with_rest(words, 'länder du äger')
      return placement_parse(rest, accumulated.push([country, armies]))
    end
  end

  def place(words = [])
    if words.empty?
      post "Användningsexempel:\n    placera 3 i Indien, -1 i Irkutsk\n    pl 3 indi -1 irk\n    pl indi 3 irk -1"
    else
      current_game!
      placements, exceptions = request(:game => @current_game, :type => :place, :placement => placement_parse(words))
      exceptions.each do |e|
        begin
          raise e
        rescue Game::TooFewArmiesException => e
          post 'För få arméer i %s!' % e.params[:country].name
        rescue Game::TooManyArmiesException => e
          post 'För många arméer i %s! Varje land får börja med max fyra arméer.' % e.params[:country].name
        end
      end
      if not placements.empty?
        post_map(@current_game)
        response = "Du har placerat ut följande arméer:\n"
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
          post 'Är du klar kan du göra "anfall". Vill du inte anfalla kan du börja direkt med att "flytta". Vill du ingetdera kan du säga "klar".'
        else
          post 'Säg "klar" om du är nöjd med placeringen av dina arméer.'
        end
      elsif @current_game.people_players[self].armies_for_placement > 0
        post 'Du har %s kvar att placera ut.' % @current_game.people_players[self].armies_for_placement.swedish_quantity('armé', 'arméer')
      else
        post 'Du har placerat ut %s mer än tillåtet. Åtgärda!' % (-@current_game.people_players[self].armies_for_placement).swedish_quantity('armé', 'arméer')
      end
    end
  end

  def done(words = [])
    current_game!
    if not @current_game.started
      post 'Spelet har inte startat ännu.'
    elsif not @hasty_done_warning and @current_game.first_placement_done and @current_game.person_in_turn(self) and
        @current_game.turn_phase == 0 and @current_game.turn_queue.first.armies_for_placement == 0
      @hasty_done_warning = true
      post 'Varning: "klar" avslutar din tur. Är du säker på att du inte vill "anfalla" eller "flytta"? Den här varningen upprepas inte.'
    else
      request(:game => @current_game, :type => :done)
    end
  end

  def attack(words = [])
    if words.empty?
      post "Synopsis:\n    anfall LAND [ från LAND ] [ med ARMÉER ] [!]\n    anfall igen"
    else
      current_game!
      countries = @current_game.people_players[self].countries.select{ |c| c.total_armies > 1 }
      attackable_countries = @current_game.people_players[self].attackable_countries
      if words.first =~ /^(igen|ige|ig)$/
        if not @last_attack
          post 'Du har inte anfallit ännu den här omgången!'
        else
          target = @last_attack[:target]
          from = @last_attack[:from]
          armies = @last_attack[:armies]
          destroy = @last_attack[:destroy]
        end
      else
        target, rest = attackable_countries.pick_from_with_rest(words, 'länder du kan anfalla')
        if @last_attack and @last_attack[:target] == target
          from = @last_attack[:from]
          armies = @last_attack[:armies]
          destroy = @last_attack[:destroy]
        else
          from = nil
          armies = nil
          destroy = false
        end
        if rest.first =~ /^(från|frå|fr|f)$/
          from, rest = countries.pick_from_with_rest(rest[1..-1], 'länder att anfalla från')
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
        post 'Det är oklart vilket land du vill anfalla från.'
      elsif not armies
        post 'Det är oklart hur många arméer du vill anfalla med.'
      else
        @last_attack = { :target => target, :from => from, :armies => armies, :destroy => destroy }
        @last_attack[:armies] = request({:game => @current_game, :type => :attack}.merge(@last_attack))
      end
    end
  rescue Game::TooFewArmiesException
    post 'Det är ett fånigt antal arméer att anfalla med.'
  rescue Game::TooManyArmiesException
    post 'Du har inte så många arméer tillgängliga för ett anfall!'
  end

  def move(words = [])
    if words.empty?
      post "Synopsis:\n    flytta ARMÉER [ från LAND ] [ till LAND ]"
    else
      countries = current_game!.people_players[self].countries
      to = nil
      from = nil
      armies = words.first.to_i
      rest = words[1..-1]
      loop do
        if rest.first =~ /^(från|frå|fr|f)$/
          from, rest = (to ? to.borders : countries).pick_from_with_rest(rest[1..-1], 'länder')
        elsif rest.first =~ /^(till|til|ti|t)$/
          to, rest = (from ? from.borders : countries).pick_from_with_rest(rest[1..-1], 'länder')
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
        post 'Det är oklart vilket land du vill flytta från.'
      elsif not to
        post 'Det är oklart vilket land du vill flytta till.'
      else
        @last_move = { :to => to, :from => from, :armies => armies }
        request({:game => @current_game, :type => :move}.merge(@last_move))
      end
    end
  rescue Game::TooFewArmiesException
    post 'Det är ett fånigt antal arméer att flytta.'
  rescue Game::TooManyArmiesException
    post 'Du får inte flytta så många arméer därifrån!'
  rescue Game::MovesExhaustedException
    post 'Du får inte flytta så många arméer!'
  end

  def post_mission(mission)
    post("Ditt uppdrag är: %s\n\nDu vinner om villkoren är eller blir uppfyllda under din tur." % mission.swedish)
  end

  def post_card_combos
    post '3xA ger fyra arméer, 3xB ger sex, 3xC ger åtta. Ett av varje ger tio. * fungerar som joker.'
  end

  def post_card_progression
    post "Giltiga kortkombinationer är tre lika kort eller tre olika kort. * fungerar som joker.\n\nVarje gång en kortkombination byts in så ändras antalet arméer man får i utbyte enligt serien %s, ..." % (1..10).collect{ |n| @current_game.progressive_card_value(n) }.join(', ')
  end

  def use_cards(words = [])
    if words.empty?
      post "Användningsexempel:\n    byt in a a a\n    byt in a b c\n    byt in c c *"
    end
    cards(words)
  end

  def cards(words = [])
    if words.empty?
      post 'Kortkombinationer kan bytas in mot extra arméer under placeringsfasen.'
      if @current_game
        if @current_game.combination_cards?
          post_card_combos
        elsif @current_game.progressive_cards?
          post_card_progression
        else
          raise RuntimeError.new
        end
        cards = @current_game.people_players[self].cards
        unless cards.values.detect{ |n| n != 0}
          post 'Du har inga kort i %s.' % @current_game.name
        else
          post 'Du har följande kort i %s: %s' % [ @current_game.name, cards_str(cards) ]
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
    post 'Det är inte en giltig kortkombination!'
  rescue Game::InsuficcentCardsException
    post 'Du har inte alla dom korten!'
  end

  def mission(words = nil)
    if current_game!.settings[:gametype].value != :mission
      post 'Hemliga uppdrag används inte i det här partiet!'
      return
    end
    if @current_game.people_players[self].mission.nil?
      post 'Du har inte tilldelats något uppdrag än!'
    else
      post_mission(@current_game.people_players[self].mission)
    end
    missions = "De möjliga uppdragen är:\n\n" + @current_game.all_missions.collect{ |m| '  ' + m.swedish }.join("\n\n")
    post missions
  end

  def map(words = [])
    if not @current_game
      post map_str(Game::Map.new(nil), true)
    elsif words.first =~ /^(namn|nam|na)$/
      post map_str(current_game!.map, true)
    elsif words.empty?
      post map_str(current_game!.map)
    else
      post map_str($state.games.pick_from(words, 'partier').map)
    end
  end

  def status(words = nil)
    if @current_game
      post 'Du är aktiv i %s.' % @current_game.name
    else
      post 'Du är inte aktiv i något parti.'
    end
    games = @games.keys.reject{ |g| g == @current_game }
    if not games.empty?
      post "Du deltar%s i:\n%s" % [ (@current_game ? ' också' : ''), games.collect{ |g| game_str(g) }.join("\n") ]
    end
    if @games.empty? and $state.open_games.empty?
      post 'Det finns inga öppna partier just nu. Skriv "nytt parti" om du vill skapa ett.'
    end
    [ [ $state.open_games, 'Öppna spel' ],
      [ $state.running_games, 'Pågående spel' ],
      [ $state.finished_games.reverse[0..2], 'Nyligen avslutade spel' ] ].each do |games, caption|
      if games and not games.empty?
        post "%s:\n%s" % [ caption, games.collect{ |g| game_str(g) }.join("\n") ]
      end
    end
  end

  def unimplemented(words = nil)
    post "Just nu förstår jag inte vad du menar. Men det blir nog bättre med tiden."
  end

  def verbose(words = nil)
    @quiet = false
    post 'Nu får du meddelanden så fort något händer i ett parti där du deltar! Säg "var smygig" om du vill ändra det.'
  end

  def quiet(words = nil)
    @quiet = true
    post 'Nu får du bara meddelanden i partier där det är din tur. Säg "var pratig" om du vill ändra det.'
  end

  def history(words = [])
    unless words.empty?
      post 'För närvarande kan du bara få en resumé som personligt meddelande.'
    else
      if has_delayed?(current_game!)
        flush_delayed(current_game!)
      else
        post 'Ingenting har hänt i %s som du inte hört om.' % @current_game.name
        unless @quiet
          post 'Den här finessen kan vara anändbar om du har sagt "var smygig".'
        end
      end
    end
  end

  def borders(words = nil)
    result = ''
    current_game!.map.continents.each do |continent|
      result << "--- %s (%s, %s)\n" % [ continent.name,
                                        continent.countries.length.swedish_quantity('land', 'länder', :neutrum => true),
                                        continent.bonus_armies.swedish_quantity('bonusarmé', 'bonusarméer') ]
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
    text = "Praktiska saker för elisp-klienten:\n\n"
    text << ';;; Bind s g till att sända ett meddelande till mig:
  (defun generalen-keybinding ()
    (local-set-key [?s ?g] (lambda nil (interactive)
  			   (set-buffer "%s")
  			   (kom-send-message %d)
  			   (switch-to-buffer "%s"))))

  (add-hook \'lyskom-mode-hook #\'generalen-keybinding)

;;; För dom vågade: ett fulhack som visar färgade kartor.
;;; Byter buffer. Är förmodligen irriterande i vissa lägen.
  (defgroup generalen \'() "Färgläggningsfulhack")
  (defface generalen-map
    \'((t (:background "darkslateblue" :foreground "white")))
    "Grundläggande face som ärvs av, och som används på kartan där inget annat passar"
    :group \'generalen)
  (defface generalen-water
    \'((t (:inherit generalen-map :foreground "slateblue" :weight bold)))
    "Vatten"
    :group \'generalen)
  (defface generalen-border
    \'((t (:inherit generalen-map :foreground "white")))
    "Gränser"
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
    "Spelaren med tecknet ¤"
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
      (generalen-reformat "¤ ?[0-9?]+" generalen-player-6)
      (setq map-start map-end)
      (setq map-end (string-match " Länder \\\\[" message))
      (when map-end
        (generalen-reformat "^  (.)[^[\\n]*" bold)
        (generalen-reformat "(#)" generalen-player-1)
        (generalen-reformat "(X)" generalen-player-2)
        (generalen-reformat "(O)" generalen-player-3)
        (generalen-reformat "(%%)" generalen-player-4)
        (generalen-reformat "(@)" generalen-player-5)
        (generalen-reformat "(¤)" generalen-player-6)
        (setq map-start map-end)
        (setq map-end (+ 1 (string-match "\\\\]" message (string-match "Plus" message map-start))))
        (generalen-reformat "#+" generalen-player-1)
        (generalen-reformat "X+" generalen-player-2)
        (generalen-reformat "O+" generalen-player-3)
        (generalen-reformat "%%+" generalen-player-4)
        (generalen-reformat "@+" generalen-player-5)
        (generalen-reformat "¤+" generalen-player-6)
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
