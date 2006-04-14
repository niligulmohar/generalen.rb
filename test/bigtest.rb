# -*- coding: iso-8859-1 -*-

require 'test/unit'
require 'util/random'
require 'util/swedish'
require 'generalen/state'
require 'generalen/game'
require 'generalen/person'
require 'fileutils'


class State
  def with_first_game
    transaction do
      yield @store[:games].first
    end
  end
  def with_first_game_and_admin
    transaction do
      yield(@store[:games].first, @store[:people][:admin])
    end
  end
end

class BigTestCase < Test::Unit::TestCase

  TEST_STATE_FILE_NAME = 'GENERALEN.test.STATE'

  def setup
    @random = Random::TestSource.new
    $state = State.new(TEST_STATE_FILE_NAME, @random);

    @names = %w{ Pelle Kalle Olle Nisse Anna Stina Svenzuno }
    @names.each do |name|
      $state.register_person(name.to_sym, Person::TestPerson, name)
    end
  end

  def teardown
    $state = nil
    FileUtils::rm(TEST_STATE_FILE_NAME);
  end

  def test_create_join_say_leave
    $state.with_person(:Pelle) do |p|
      p.command('ny')
      assert_match( /Du har skapat F�rsta partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
    end
    @names[1..5].each do |name|
      $state.with_person(name.to_sym) do |p|
        p.command('de')
        assert_match( /Du har g�tt med i F�rsta partiet/, p.get )
        assert_match( /Inst�llningar f�r/, p.get )
        assert_match( /Deltagare i/, p.get )
        assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
      end
    end
    $state.with_person(:Svenzuno) do |p|
      p.command('de')
      assert_match( /F�rsta partiet �r fullt!/, p.get )
    end
    @names[0..5].each_with_index do |name, i|
      $state.with_person(name.to_sym) do |p|
        (i+1).upto(5) do |n|
          assert_match( /#{@names[n]} har g�tt med i F�rsta partiet/, p.get )
          assert_match( /Skriv "b�rja"/, p.get )
        end
      end
    end
    $state.with_person(:Pelle) do |p|
      p.command('s�g Tomtar gillar potatis')
    end
    @names[0..5].each_with_index do |name, i|
      $state.with_person(name.to_sym) do |p|
        assert_match( /Pelle.*F�rsta partiet.*Tomtar gillar potatis/m, p.get )
        p.command('l�')
        0.upto(i) do |n|
          assert_match( /#{@names[n]} har l�mnat F�rsta partiet/, p.get )
          assert_match( /Skriv "b�rja"/, p.get ) if n < 4
        end
        if i == 5
          assert_match( /F�rsta partiet har upph�rt/, p.get )
        end
        assert_nil( p.get )
      end
    end
  end

  def test_create_settings_start_twoplayer_surrender
    $state.with_person(:Pelle) do |p|
      p.command('ny')
      assert_match( /Du har skapat F�rsta partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
      p.command('s�t spe = v')
      assert_match( /V�rldsdominans/, p.get )
      p.command('b�')
      assert_match( /Det kr�vs mer �n en/, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      p.command('de')
      assert_match( /Du har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
      p.command('b�')
      assert_match( /Svenzuno �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Svenzuno har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Skriv "b�rja"/, p.get )
      assert_match( /Svenzuno �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
      p.command('s�t spe = v')
      assert_match( /V�rldsdominans/, p.get )
      assert_match( /Skriv "b�rja"/, p.get )
      p.command('b�')
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /V�ntar p�.*Svenzuno/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /V�rldsdominans/, p.get )
      assert_match( /Du m�ste skriva "b�rja" igen/, p.get )
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /V�ntar p�.*Svenzuno/m, p.get )
      p.command('s�t dra = 1')
      assert_match( /en minut/, p.get )
      assert_match( /Du m�ste skriva "b�rja" igen/, p.get )
      p.command('b�')
      assert_match( /Svenzuno �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
    end
    $state.with_random_source do |r|
      r.choose_results.push([1, 0])
      r.choose_results.push(*((0..41).collect.reverse.collect{ |n| [n] }))
      r.randrange_results.push(4, 5, 6, 1, 2)
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /en minut/, p.get )
      assert_match( /Du m�ste skriva "b�rja" igen/, p.get )
      assert_match( /Svenzuno �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
      p.command('b�')
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle/m, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 26 arm�er/m, p.get )
      p.command('karta')
      assert_match( /~/, p.get )
      p.command('pl 3 � a 3 arg 3 indo 3 bra 3 sia 3 norda 3 kin v�steu 3 v f 2')
      assert_match( /Du har placerat/, p.get )
      assert_match( /S�g "klar"/, p.get )
      p.command('kl')
      assert_match( /Pelle �r klar/, p.get )
      assert_match( /V�ntar p�.*Svenzuno/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle/m, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 26 arm�er/m, p.get )
      assert_match( /Pelle �r klar/, p.get )
      assert_match( /V�ntar p�.*Svenzuno/m, p.get )
      p.command('pl v a 3 mada 3 kon 3 per 3 indi 3 mel 3 sydeu 3 jap 3 mon 2')
      assert_match( /Du har placerat/, p.get )
      assert_match( /S�g "klar"/, p.get )
      p.command('kl')
      assert_match( /Svenzuno �r klar/, p.get )
      assert_match( /Det �r din tur/, p.get )
      assert_match( /Du f�r inga arm�er f�rsta rundan/, p.get )
      p.command('anf n g fr�n v a med 3')
      assert_match( /Svenzuno.*anfaller.*Neutral.*6...5...4.*2...1/m, p.get )
      assert_match( /Svenzuno er�vrar Nya Guinea/m, p.get )
      p.command('kap!')
      assert_match( /Svenzuno har kapitulerat/, p.get )
      assert_match( /Pelle har vunnit/, p.get )
      assert_nil( p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Svenzuno �r klar/, p.get )
      assert_match( /Turen �verg�r till Svenzuno/, p.get )
      assert_match( /Svenzuno.*anfaller.*Neutral.*6...5...4.*2...1/m, p.get )
      assert_match( /Svenzuno er�vrar Nya Guinea/m, p.get )
      assert_match( /Svenzuno har kapitulerat/, p.get )
      assert_match( /Pelle har vunnit/, p.get )
      assert_nil( p.get )
    end
  end

  def test_create_start_mission
    $state.with_person(:Pelle) do |p|
      p.command('ny')
      assert_match( /Du har skapat F�rsta partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      p.command('de')
      assert_match( /Du har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
      p.command('b�')
      assert_match( /Det kr�vs minst tre/, p.get )
    end
    $state.with_person(:Stina) do |p|
      p.command('de')
      assert_match( /Du har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
      p.command('b�')
      assert_match( /Stina �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle.*Svenzuno/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Stina har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Skriv "b�rja"/, p.get )
      assert_match( /Stina �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle.*Svenzuno/m, p.get )
      p.command('b�')
      assert_match( /Svenzuno �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
    end
    $state.with_random_source do |r|
      r.choose_results.push([1, 0, 2], [1], [7], [4])
      r.choose_results.push(*((0..41).collect.reverse.collect{ |n| [n] }))
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Svenzuno har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Skriv "b�rja"/, p.get )
      assert_match( /Stina har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Skriv "b�rja"/, p.get )
      assert_match( /Stina �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle.*Svenzuno/m, p.get )
      assert_match( /Svenzuno �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
      p.command('b�')
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle/m, p.get )
      assert_match( /Ditt uppdrag.*Er�vra Asien och Afrika/, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 21 arm�er/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle.*Stina/m, p.get )
      assert_match( /Ditt uppdrag.*Utpl�na Pelle/, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 21 arm�er/m, p.get )
      p.command('pl ven 3 n g 3 syda 3 �sta 3')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Du har nio arm�er kvar/, p.get )
      p.command('pl egy -1')
      assert_match( /F�r f� arm�er/, p.get )
      assert_match( /Du har nio arm�er kvar/, p.get )
      p.command('pl egy 5')
      assert_match( /F�r m�nga arm�er/, p.get )
      assert_match( /Du har nio arm�er kvar/, p.get )
      p.command('pl egy = 3, 3 i cen och 3 i afg')
      assert_match( /Du har placerat/, p.get )
      assert_match( /S�g "klar"/, p.get )
      p.command('kl')
      assert_match( /Svenzuno �r klar/, p.get )
      assert_match( /V�ntar p�.*Pelle.*Stina/m, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Svenzuno �r klar/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
      p.command('pl 3 v a 3 mada 3 kon 3 per 3 indi 3 mel 3 syde 3 jap')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Du har placerat ut tre arm�er mer.*�tg�rda/, p.get )
      p.command('pl -3 jap')
      assert_match( /Du har placerat/, p.get )
      assert_match( /S�g "klar"/, p.get )
      p.command('kl')
      assert_match( /Pelle �r klar/, p.get )
      assert_match( /V�ntar p�.*Stina/m, p.get )
    end
    $state.with_person(:Stina) do |p|
      assert_match( /Svenzuno �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle.*Stina/m, p.get )
      assert_match( /Ditt uppdrag.*Er�vra Europa och Australien/, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 21 arm�er/m, p.get )
      assert_match( /Svenzuno �r klar/, p.get )
      assert_match( /V�ntar p�.*Pelle.*Stina/m, p.get )
      assert_match( /Pelle �r klar/, p.get )
      assert_match( /V�ntar p�.*Stina/m, p.get )
      p.command('pl 3 � a 3 arg 3 indo 3 bra 3 sia 3 norda 3 kin')
      assert_match( /Du har placerat/, p.get )
      assert_match( /S�g "klar"/, p.get )
      p.command('kl')
      assert_match( /Stina �r klar/, p.get )
      assert_match( /Turen �verg�r till Svenzuno/, p.get )
    end
    $state.with_random_source do |r|
      r.randrange_results.push(4, 5, 6, 1, 2)
      r.randrange_results.push(3, 2, 1, 3, 2)
      r.randrange_results.push(6, 1, 1)
      r.randrange_results.push(6, 1)
      r.randrange_results.push(39)
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Pelle �r klar/, p.get )
      assert_match( /V�ntar p�.*Stina/m, p.get )
      assert_match( /Stina �r klar/, p.get )
      assert_match( /Det �r din tur/, p.get )
      assert_match( /Du f�r inga arm�er f�rsta rundan/, p.get )
      p.command('an kon fr syda med 0')
      assert_match( /Det �r ett f�nigt antal arm�er att anfalla med/, p.get )
      p.command('an kon fr syda med 666')
      assert_match( /Du har inte s� m�nga arm�er tillg�ngliga/, p.get )
      p.command('an kon fr syda med 3')
      assert_match( /Svenzuno.*anfaller.*Pelle.*6...5...4.*2...1/m, p.get )
      p.command('an ig')
      assert_match( /Svenzuno.*anfaller.*Pelle.*3...2...1.*3...2/m, p.get )
      p.command('an ig')
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1...1/m, p.get )
      p.command('an ig')
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1/m, p.get )
      assert_match( /Svenzuno er�vrar Kongo/m, p.get )
      p.command('pl �sta -1')
      assert_match( /Du f�r inte placera arm�er eller anv�nda kort, f�r du har redan anfallit/, p.get )
      p.command('fl 1 fr�n �sta till kon')
      assert_match( /Svenzuno flyttar en arm� fr�n/, p.get )
      p.command('fl 1 fr�n syda till kon')
      assert_match( /Du f�r inte flytta s� m�nga arm�er d�rifr�n/, p.get )
      p.command('fl 0')
      assert_match( /Det �r ett f�nigt antal arm�er att flytta/, p.get )
      p.command('anf Norda fr�n kon med 2')
      assert_match( /Du f�r inte anfalla, f�r du har redan flyttat/, p.get )
      p.command('fl 3 fr�n egy till �sta')
      assert_match( /Svenzuno flyttar tre arm�er fr�n/, p.get )
      p.command('fl 2 fr�n �sta till kon')
      assert_match( /Svenzuno flyttar tv� arm�er fr�n/, p.get )
      p.command('fl 1 fr�n �sta till kon')
      assert_match( /Svenzuno flyttar en arm� fr�n/, p.get )

      assert_match( /Du f�r ett kort.*C/, p.get )
      assert_match( /Turen �verg�r till Pelle/, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Stina �r klar/, p.get )
      assert_match( /Turen �verg�r till Svenzuno/, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6...5...4.*2...1/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*3...2...1.*3...2/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1...1/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1/m, p.get )
      assert_match( /Svenzuno er�vrar Kongo/m, p.get )
      assert_match( /Svenzuno flyttar en arm� fr�n/, p.get )
      assert_match( /Svenzuno flyttar tre arm�er fr�n/, p.get )
      assert_match( /Svenzuno flyttar tv� arm�er fr�n/, p.get )
      assert_match( /Svenzuno flyttar en arm� fr�n/, p.get )
      assert_match( /Svenzuno f�r ett kort/, p.get )
      assert_match( /Det �r din tur/, p.get )
      assert_match( /Du f�r inga arm�er f�rsta rundan/, p.get )
      p.command('kl')
      assert_match( /Varning/, p.get )
      p.command('kl')
      assert_match( /Turen �verg�r till Stina/, p.get )
    end
    $state.with_person(:Stina) do |p|
      assert_match( /Svenzuno.*anfaller.*Pelle.*6...5...4.*2...1/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*3...2...1.*3...2/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1...1/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1/m, p.get )
      assert_match( /Svenzuno er�vrar Kongo/m, p.get )
      assert_match( /Svenzuno flyttar en arm� fr�n/, p.get )
      assert_match( /Svenzuno flyttar tre arm�er fr�n/, p.get )
      assert_match( /Svenzuno flyttar tv� arm�er fr�n/, p.get )
      assert_match( /Svenzuno flyttar en arm� fr�n/, p.get )
      assert_match( /Svenzuno f�r ett kort/, p.get )
      assert_match( /Turen �verg�r till Pelle/, p.get )
      assert_match( /Det �r din tur/, p.get )
      assert_match( /Du f�r inga arm�er f�rsta rundan/, p.get )
      p.command('kl')
      assert_match( /Varning/, p.get )
      p.command('kl')
      assert_match( /Turen �verg�r till Svenzuno/, p.get )
    end
    $state.with_random_source do |r|
      r.randrange_results.push(6, 6, 6, 1, 1)
      r.randrange_results.push(6, 6, 6, 1, 1)
      r.randrange_results.push(0)
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Turen �verg�r till Stina/, p.get )
      assert_match( /Det �r din tur/, p.get )
      assert_match( /Du har fem nya arm�er/, p.get )
      p.command('ko')
      assert_match( /Anv�ndn/, p.get )
      assert_match( /Du har f�ljande kort.*C/, p.get )
      assert_match( /Ditt uppdrag.*Utpl�na Pelle/, p.get )
      p.command('ko a a b')
      assert_match( /Det �r inte en giltig kortkombination/, p.get )
      p.command('ko a b c')
      assert_match( /Du har inte alla dom korten/, p.get )
      p.command('pl kon 5')
      assert_match( /Du har placerat ut/, p.get )
      assert_match( /�r du klar/, p.get )
      p.command('an norda fr kon med 6!')
      assert_match( /Svenzuno placerar ut/, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno er�vrar Nordafrika/m, p.get )
      p.command('ko a b c')
      assert_match( /Du f�r inte placera arm�er eller anv�nda kort, f�r du har redan anfallit/, p.get )
      p.command('kl')
      assert_match( /Du f�r ett kort.*A/, p.get )
      assert_match( /Turen �verg�r till Pelle/, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Turen �verg�r till Svenzuno/, p.get )
      assert_match( /Svenzuno placerar ut/, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno er�vrar Nordafrika/m, p.get )
      assert_match( /Svenzuno f�r ett kort/, p.get )
      assert_match( /Det �r din tur/, p.get )
      assert_match( /Du har fyra nya arm�er/, p.get )
      p.command('kl')
      assert_match( /Du f�r inte avsluta din tur/, p.get )
      p.command('pl v a 4')
      assert_match( /Du har placerat/, p.get )
      assert_match( /�r du klar/, p.get )
      p.command('kl')
      assert_match( /Pelle placerar ut/, p.get )
      assert_match( /Turen �verg�r till Stina/, p.get )
    end
    $state.with_person(:Stina) do |p|
      assert_match( /Svenzuno placerar ut/, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno er�vrar Nordafrika/m, p.get )
      assert_match( /Svenzuno f�r ett kort/, p.get )
      assert_match( /Turen �verg�r till Pelle/, p.get )
      assert_match( /Pelle placerar ut/, p.get )
      assert_match( /Det �r din tur/, p.get )
      assert_match( /Du har fyra nya arm�er/, p.get )
      [ :a, :b, :c ].each do |c|
        p.current_game.people_players[p].recieve_card(c)
      end
      p.command('ko')
      assert_match( /exempel/, p.get )
      assert_match( /.A. .B. .C./, p.get )
      assert_match( /uppdrag/, p.get )
      p.command('ko a b c')
      assert_match( /Stina f�r tio extra arm�er f�r f�ljande kort/, p.get )
      p.command('ko')
      assert_match( /exempel/, p.get )
      assert_match( /Inga kort/, p.get )
      assert_match( /uppdrag/, p.get )
    end
  end

  def test_multiple_games
    $state.with_person(:Pelle) do |p|
      p.command('ny')
      assert_match( /Du har skapat F�rsta partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
      p.command('s�t spe=v�r')
      assert_match( /V�rldsdominans/, p.get )
    end
    $state.with_person(:Stina) do |p|
      p.command('de')
      assert_match( /Du har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
      p.command('b�')
      assert_match( /Stina �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Stina har g�tt med i F�rsta partiet/, p.get )
      assert_match( /Skriv "b�rja"/, p.get )
      assert_match( /Stina �r redo att b�rja i F�rsta partiet/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
      p.command('ny')
      assert_match( /Du har skapat Andra partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Du �r nu aktiv i Andra partiet/, p.get )
      p.command('s�t spe=v�r')
      assert_match( /V�rldsdominans/, p.get )
    end
    $state.with_person(:Stina) do |p|
      p.command('de')
      assert_match( /Du har g�tt med i Andra partiet/, p.get )
      assert_match( /Inst�llningar f�r/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du �r nu aktiv i Andra partiet/, p.get )
      p.command('b�')
      assert_match( /Stina �r redo/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
    end
    $state.with_random_source do |r|
      2.times do
        r.choose_results.push([0, 1])
        r.choose_results.push(*((0..41).collect.reverse.collect{ |n| [n] }))
      end
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Stina har g�tt med i Andra partiet/, p.get )
      assert_match( /Skriv "b�rja"/, p.get )
      assert_match( /Stina �r redo att b�rja i Andra partiet/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
      p.command('g� f�')
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
      p.command('b�')
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 26 arm�er/m, p.get )
    end
    # Byte fr�n �ppet parti till parti d�r f�rsta placering b�rjar
    $state.with_person(:Stina) do |p|
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 26 arm�er/m, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
    end
    $state.with_person(:Pelle) do |p|
      p.command('g� an')
      assert_match( /Du �r nu aktiv i Andra partiet/, p.get )
      p.command('b�')
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /Andra partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 26 arm�er/m, p.get )
    end
    # Inget byte fr�n ett parti d�r f�rsta placeringen p�g�r
    $state.with_person(:Stina) do |p|
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /Andra partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas fjorton l�nder.*Du har 26 arm�er/m, p.get )
      assert_nil( p.get )
    end
    # Byte till ett parti d�r f�rsta placeringen p�g�r, n�r man �r klar
    $state.with_person(:Stina) do |p|
      p.command('pl 3 � a 3 arg 3 indo 3 bra 3 sia 3 norda 3 kin v�steu 3 v f 2')
      #p.command('pla 3 � a 3 syda 3 mada 3 indo 3 �sta 2 peru 2 sia')
      assert_match( /Du har placerat/, p.get )
      assert_match( /S�g "klar"/, p.get )
      p.command('kl')
      assert_match( /Stina �r klar/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
      assert_match( /Du �r nu aktiv i Andra partiet/, p.get )
    end
    $state.with_person(:Stina) do |p|
      p.command('pl 3 � a 3 arg 3 indo 3 bra 3 sia 3 norda 3 kin v�steu 3 v f 2')
      #p.command('pla 3 � a 3 syda 3 mada 3 indo 3 �sta 2 peru 2 sia')
      assert_match( /Du har placerat/, p.get )
      assert_match( /S�g "klar"/, p.get )
      p.command('kl')
      assert_match( /Stina �r klar/, p.get )
      assert_match( /V�ntar p�.*Pelle/m, p.get )
    end
  end

  def test_winning_specific_continents
    players = start_game(:missions => [0, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Er�vra Asien och Sydamerika/, g.players.first.mission.swedish )
    end
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   X 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ O 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  # 1 / # 1 \~~~~~~~
\__  / X 1 /   /~~~___~\/~/ O 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ X 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ O 1 \/ X 1 \~~~~~~___\  /~~\     \~~/  \ # 1 \   \ # 1 \  \~~/   \~
~~~~~\ X 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 1 \~~~____/   X 1  \___  \ # 1 /    \/~/  \~
~~~~\           \  O 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 1 /~/    \\
~~~~~\   X 1    /  __  \~~~~~~~~~______/ O 1 \_     __/    \__\__\    /~/ # 1 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ X 1 /        \_ \~~/ # 1 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ O 1 __/~\ \~\    /    # 1    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ X 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 1  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    X 1   \ O 1 \/   \__~\  # 1  /\ # 1 /~~~~~~~~
~~~~~~~~~~~~/    X 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ # 2 \_ # 1  /~~~~~~~~\    \  X 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ O 1 \      /~____~~~~~~~~~~/ X 1 \~\ O 1 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 1_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ # 1  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ X 1 \~\___/~~~~~~~~~~/   O 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  X 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_random_source do |r|
      r.randrange_results.push(6, 1)
    end
    $state.with_person(players.first) do |p|
      p.command('anfall venezuela fr�n peru med 1')
      assert_match( /Pelle.*anfaller.*Kalle/m, p.get )
      assert_match( /Pelle er�vrar Venezuela/m, p.get )
      assert_match( /Pelle har vunnit.*!/m, p.get )
    end
  end

  def test_winning_specific_continents_plus_one
    players = start_game(:missions => [5, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Er�vra Europa och Australien, samt ytterligare en valfri kontinent/, g.players.first.mission.swedish )
    end
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   X 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ O 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  O 1 / O 1 \~~~~~~~
\__  / X 1 /   /~~~___~\/~/ # 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ # 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ O 1 \/ X 1 \~~~~~~___\  /~~\     \~~/  \ X 1 \   \ X 1 \  \~~/   \~
~~~~~\ X 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 1 \~~~____/   # 1  \___  \ # 1 /    \/~/  \~
~~~~\           \  O 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 1 /~/    \\
~~~~~\   X 1    /  __  \~~~~~~~~~______/ # 1 \_     __/    \__\__\    /~/ # 1 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ # 1 /        \_ \~~/ X 1 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ # 1 __/~\ \~\    /    O 1    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ X 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 1  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    X 1   \ O 1 \/   \__~\  # 1  /\ O 1 /~~~~~~~~
~~~~~~~~~~~~/    # 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ # 1 \_ # 1  /~~~~~~~~\    \  X 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ O 1 \      /~____~~~~~~~~~~/ X 1 \~\ # 2 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 1_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ # 1  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ X 1 \~\___/~~~~~~~~~~/   # 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  # 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_random_source do |r|
      r.randrange_results.push(6, 1)
    end
    $state.with_person(players.first) do |p|
      p.command('anfall indonesien fr�n nya guinea med 1')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_n_countries
    players = start_game(:missions => [7, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Er�vra 24 valfria l�nder/, g.players.first.mission.swedish )
    end
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   X 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ O 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  O 1 / O 1 \~~~~~~~
\__  / X 1 /   /~~~___~\/~/ # 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ # 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ O 1 \/ X 1 \~~~~~~___\  /~~\     \~~/  \ X 1 \   \ X 1 \  \~~/   \~
~~~~~\ X 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 1 \~~~____/   # 1  \___  \ # 1 /    \/~/  \~
~~~~\           \  O 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 1 /~/    \\
~~~~~\   # 1    /  __  \~~~~~~~~~______/ # 1 \_     __/    \__\__\    /~/ # 1 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ # 1 /        \_ \~~/ X 1 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ # 1 __/~\ \~\    /    O 1    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ X 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 1  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    X 1   \ # 2 \/   \__~\  # 1  /\ O 1 /~~~~~~~~
~~~~~~~~~~~~/    # 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ O 1 \_ # 1  /~~~~~~~~\    \  # 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ O 1 \      /~____~~~~~~~~~~/ X 1 \~\ # 1 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 1_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ # 1  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ # 1 \~\___/~~~~~~~~~~/   # 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  # 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_random_source do |r|
      r.randrange_results.push(6, 1)
    end
    $state.with_person(players.first) do |p|
      p.command('anfall nordafrika fr�n egypten med 1')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_n_countries_n_armies_by_attacking
    players = start_game(:missions => [6, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Er�vra 18 valfria l�nder och placera minst 2 arm�er i varje land/, g.players.first.mission.swedish )
    end
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   X 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ O 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  # 2 / # 2 \~~~~~~~
\__  / X 1 /   /~~~___~\/~/ O 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ X 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ O 1 \/ X 1 \~~~~~~___\  /~~\     \~~/  \ # 4 \   \ # 2 \  \~~/   \~
~~~~~\ X 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 2 \~~~____/   X 1  \___  \ # 2 /    \/~/  \~
~~~~\           \  O 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 2 /~/    \\
~~~~~\   X 1    /  __  \~~~~~~~~~______/ O 1 \_     __/    \__\__\    /~/ # 2 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ X 1 /        \_ \~~/ # 2 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ O 1 __/~\ \~\    /    # 2    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ X 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 2  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    X 1   \ O 1 \/   \__~\  # 2  /\ # 2 /~~~~~~~~
~~~~~~~~~~~~/    X 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ # 2 \_ # 2  /~~~~~~~~\    \  X 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ O 1 \      /~____~~~~~~~~~~/ X 1 \~\ O 1 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 2_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ # 2  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ X 1 \~\___/~~~~~~~~~~/   O 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  X 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_random_source do |r|
      r.randrange_results.push(6, 6, 1, 1)
    end
    $state.with_person(players.first) do |p|
      p.command('anfall ukraina fr�n ural med 2')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_n_countries_n_armies_by_moving
    players = start_game(:missions => [6, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Er�vra 18 valfria l�nder och placera minst 2 arm�er i varje land/, g.players.first.mission.swedish )
    end
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   X 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ O 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  # 2 / # 2 \~~~~~~~
\__  / X 1 /   /~~~___~\/~/ O 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ X 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ O 1 \/ X 1 \~~~~~~___\  /~~\     \~~/  \ # 3 \   \ # 2 \  \~~/   \~
~~~~~\ X 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 2 \~~~____/   # 1  \___  \ # 2 /    \/~/  \~
~~~~\           \  O 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 2 /~/    \\
~~~~~\   X 1    /  __  \~~~~~~~~~______/ O 1 \_     __/    \__\__\    /~/ # 2 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ X 1 /        \_ \~~/ # 2 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ O 1 __/~\ \~\    /    # 2    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ X 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 2  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    X 1   \ O 1 \/   \__~\  # 2  /\ # 2 /~~~~~~~~
~~~~~~~~~~~~/    X 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ # 2 \_ # 2  /~~~~~~~~\    \  X 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ O 1 \      /~____~~~~~~~~~~/ X 1 \~\ O 1 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 2_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ # 2  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ X 1 \~\___/~~~~~~~~~~/   O 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  X 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_person(players.first) do |p|
      p.command('flytta 1 fr�n ural till ukraina')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_n_countries_n_armies_by_placement
    players = start_game(:missions => [6, 0, 0], :armies_for_placement => 1)
    $state.with_first_game do |g|
      assert_match( /Er�vra 18 valfria l�nder och placera minst 2 arm�er i varje land/, g.players.first.mission.swedish )
    end
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   X 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ O 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  # 2 / # 2 \~~~~~~~
\__  / X 1 /   /~~~___~\/~/ O 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ X 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ O 1 \/ X 1 \~~~~~~___\  /~~\     \~~/  \ # 2 \   \ # 2 \  \~~/   \~
~~~~~\ X 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 2 \~~~____/   # 1  \___  \ # 2 /    \/~/  \~
~~~~\           \  O 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 2 /~/    \\
~~~~~\   X 1    /  __  \~~~~~~~~~______/ O 1 \_     __/    \__\__\    /~/ # 2 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ X 1 /        \_ \~~/ # 2 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ O 1 __/~\ \~\    /    # 2    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ X 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 2  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    X 1   \ O 1 \/   \__~\  # 2  /\ # 2 /~~~~~~~~
~~~~~~~~~~~~/    X 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ # 2 \_ # 2  /~~~~~~~~\    \  X 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ O 1 \      /~____~~~~~~~~~~/ X 1 \~\ O 1 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 2_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ # 2  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ X 1 \~\___/~~~~~~~~~~/   O 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  X 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_person(players.first) do |p|
      p.command('placera 2 i ukraina')
    end
    $state.with_first_game do |g|
      assert(! g.players.first.winner)
      assert(! g.finished)
    end
    $state.with_person(players.first) do |p|
      p.command('placera -2 i ukraina')
      p.command('placera 1 i ukraina')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_eliminate_player_two
    players = start_game(:missions => [9, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Utpl�na Kalle. Om du �r Kalle/, g.players.first.mission.swedish )
    end
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   O 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ O 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  # 1 / # 1 \~~~~~~~
\__  / O 1 /   /~~~___~\/~/ O 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ O 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ O 1 \/ # 1 \~~~~~~___\  /~~\     \~~/  \ # 1 \   \ # 1 \  \~~/   \~
~~~~~\ O 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 1 \~~~____/   X 1  \___  \ # 1 /    \/~/  \~
~~~~\           \  O 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 1 /~/    \\
~~~~~\   O 1    /  __  \~~~~~~~~~______/ O 1 \_     __/    \__\__\    /~/ # 1 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ O 1 /        \_ \~~/ # 2 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ O 1 __/~\ \~\    /    # 1    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ O 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 1  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    O 1   \ O 1 \/   \__~\  # 1  /\ # 1 /~~~~~~~~
~~~~~~~~~~~~/    O 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ # 1 \_ # 1  /~~~~~~~~\    \  O 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ O 1 \      /~____~~~~~~~~~~/ O 1 \~\ O 1 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 1_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ # 1  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ O 1 \~\___/~~~~~~~~~~/   O 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  # 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_random_source do |r|
      r.randrange_results.push(6, 1)
    end
    $state.with_person(players.first) do |p|
      p.command('anfall ukraina fr�n afghanistan med 1')
      assert_match( /Pelle.*anfaller.*Kalle/m, p.get )
      assert_match( /Pelle er�vrar Ukraina/m, p.get )
      assert_match( /Kalle �r besegrad/m, p.get )
      assert_match( /Pelle har vunnit.*!/m, p.get )
    end
  end

  def test_winning_fallback_mission
    players = start_game(:missions => [0, 9, 0])
    $state.with_first_game do |g|
      assert_match( /Utpl�na Olle. Om du �r Olle/, g.players[1].mission.swedish )
      g.players[2].cards[:a] = 2
    end
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   X 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ X 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  # 1 / # 1 \~~~~~~~
\__  / X 1 /   /~~~___~\/~/ X 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ X 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ X 1 \/ # 1 \~~~~~~___\  /~~\     \~~/  \ # 2 \   \ # 1 \  \~~/   \~
~~~~~\ X 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 1 \~~~____/   O 1  \___  \ # 1 /    \/~/  \~
~~~~\           \  X 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 1 /~/    \\
~~~~~\   X 1    /  __  \~~~~~~~~~______/ X 1 \_     __/    \__\__\    /~/ # 1 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ X 2 /        \_ \~~/ X 1 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ X 1 __/~\ \~\    /    # 1    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ X 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 1  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    X 1   \ X 1 \/   \__~\  # 1  /\ # 1 /~~~~~~~~
~~~~~~~~~~~~/    X 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ # 1 \_ # 1  /~~~~~~~~\    \  X 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ X 1 \      /~____~~~~~~~~~~/ X 1 \~\ X 1 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 1_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ # 1  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ X 1 \~\___/~~~~~~~~~~/   X 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  # 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_random_source do |r|
      r.randrange_results.push(6, 1, 0, 6, 1)
    end
    $state.with_person(:Pelle) do |p|
      p.command('anfall ukraina fr�n ural med 1')
      assert_match( /Pelle.*anfaller.*Olle/m, p.get )
      assert_match( /Pelle er�vrar Ukraina/m, p.get )
      assert_match( /Olle �r besegrad/m, p.get )
      assert_match( /Du �vertar f�ljande kort.*A.*A/m, p.get )
      p.command('kort')
      assert_match( /exempel/, p.get )
      assert_match( /.A. .A./, p.get )
      assert_match( /uppdrag/, p.get )
      p.command('klar')
      assert_match( /Du f�r ett kort.*A/, p.get )
      assert_match( /Turen �verg�r till Kalle/, p.get )
    end
    $state.with_person(:Kalle) do |p|
      assert_match( /Pelle.*anfaller.*Olle/m, p.get )
      assert_match( /Pelle er�vrar Ukraina/m, p.get )
      assert_match( /Olle �r besegrad/m, p.get )
      assert_match( /Pelle �vertar tv� kort/m, p.get )
      assert_match( /Pelle f�r ett kort/m, p.get )
      assert_match( /Det �r din tur/m, p.get )
      assert_match( /Du f�r inga arm�er f�rsta rundan/, p.get )
      p.command('anfall storbritannien fr�n v�steuropa med 1')
      assert_match( /Kalle.*anfaller.*Pelle/m, p.get )
      assert_match( /Kalle er�vrar Storbritannien/m, p.get )
      assert_match( /Kalle har vunnit.*!/m, p.get )
    end
  end

  def test_winning_world_domination
    players = start_game(:players => 2)
    setup_map('~~~~~~~~~~___~~~_____________~~~~~~~~~~~~~~~~~_____~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~/   \~/             \~~~~~~~~~~~~~~~/  /  \~~~~__~~~~~~~~~~________~~~
~~____~~~\___/~\__   # 1   __/~~~~~~~~~~~~~~/  / __/~~~/  \________/       /~~~
~/    \__________~\___    /~____~~~~~~~~~~_/   \ \____/   /       /    ___/~~~~
/ # 1 /     /   /~~~~~\  /~/    \~~~~~~~~/      \ \   \   \  # 1 / # 1 \~~~~~~~
\__  / # 1 /   /~~~___~\/~/ # 1 /~____~~/     _  \ \   \   \_____\   /\ \~~~~~~
~~~\ \____/    \~~/   \~~~\____/~/   /~/ # 1 /~\_/ /    \   \     \  \~\/~___~~
~~~~\/    \ # 1 \/ # 1 \~~~~~~___\  /~~\     \~~/  \ # 1 \   \ # 1 \  \~~/   \~
~~~~~\ # 1 \     \     /__~~~/  // /~~~~\   _/~/    \     \   \__   \  \~\  __\\
~~~~~/______\____/____/  /~~~\_//  \_~~~~\_/~~/      \     \     \___\_ \~\ \~~
~~~~/          \        /~~~~~~/ # 1 \~~~____/   # 1  \___  \ # 1 /    \/~/  \~
~~~~\           \  # 1 /~~~~~~~\_____/~~/   \          /  \  \   / # 1 /~/    \\
~~~~~\   # 1    /  __  \~~~~~~~~~______/ # 1 \_     __/    \__\__\    /~/ # 1 /
~~~~~~\        /  /~~\__\~~~~~~~~\     \_____/ \   /~~\     \     \__ \~\   _/~
~~~~~~~\______/__/~~~~~~~~~~~~~__/ # 1 /        \_ \~~/ # 1 /        \_\~\_/~~~
~~~~~~~~\_      /~__~~~~~~~~~~/     __/__ # 1 __/~\ \~\    /    # 1    /~~~~~~~
~~~~~~~~~~\     \/ /~~~~~~~~~~\____/~~~~/____/~~__/__\/    \          /~~~~~~~~
~~~~~~~~~~~\ # 1  /~~~~~~~~~~~~~___~~~~~~~~~~~~/      \_____\___     /~~~~~~~~~
~~~~~~~~~~~~\___  \~~~~~~~~~~~~/   \_________~~\__ # 1  /       \___/_~~~~~~~~~
~~~~~~~~~~~~~~~~\__\~~~~~~~~~~/         /    \~~_/ ____/        /     \~~~~~~~~
~~~~~~~~~~~~~___/   \___~~~~~/    # 1   \ # 1 \/   \__~\  # 1  /\ # 1 /~~~~~~~~
~~~~~~~~~~~~/    # 1   _\~~~/            \     \     /~~\     /~~\   /~~~~~~~~~
~~~~~~~~~~~/__________/  \~~\     _______/_____/\___/~~~~\   /~~~~\_/~~~~~~~~~~
~~~~~~~~~~~\     \        \~~\___/_    \      \___~~~~~~~~\_/~~~~~~__~~~~___~~~
~~~~~~~~~~~~\ # 1 \_ # 2  /~~~~~~~~\    \  # 1   /~~~~~~~~~~~~~~~_/  \~~/   \_~
~~~~~~~~~~~~~\______\    /~~~~~~~~~/ # 1 \      /~____~~~~~~~~~~/ # 1 \~\ # 1 \\
~~~~~~~~~~~~~~\     /  _/~~~~~~~~~~\      \____/~/    \~~~~~~~~~\_____/~~\____/
~~~~~~~~~~~~~~/     \_/~~~~~~~~~~~~~\_____/   /~/ # 1_/~~~~~~~~~~~__________~~~
~~~~~~~~~~~~~/ X 1  /~~~~~~~~~~~~~~~~~\      /~/    /~~~~~~~~~~__/     __/  \~~
~~~~~~~~~~~~/      /~~~~~~~~~~~~~~~~~~~\ # 1 \~\___/~~~~~~~~~~/   # 1 /      \~
~~~~~~~~~~~~\     /~~~~~~~~~~~~~~~~~~~~~\    /~~~~~~~~~~~~~~~~\      /  # 1  /~
~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~\__/~~~~~~~~~~~~~~~~~/_____/_______/~~')
    $state.with_random_source do |r|
      r.randrange_results.push(6, 1)
    end
    $state.with_person(players.first) do |p|
      p.command('anfall arg fr�n bra med 1')
      assert_match( /Pelle.*anfaller.*Kalle/m, p.get )
      assert_match( /Pelle er�vrar Argentina/m, p.get )
      assert_match( /Kalle �r besegrad/m, p.get )
      assert_match( /Pelle har vunnit.*!/m, p.get )
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  private

  def start_game(params = {})
    if params.has_key?(:missions)
      n_players = params[:missions].length
    else
      n_players = params[:players]
    end
    players = @names[0...n_players].collect { |name| name.to_sym }
    $state.with_person(players.first) do |p|
      p.command('nytt parti')
      p.command('s�tt speltyp=v�rldsdominans') unless params.has_key?(:missions)
    end
    players[1..-1].each do |player|
      $state.with_person(player) do |p|
        p.command('deltag')
      end
    end
    $state.with_random_source do |r|
      r.choose_results.push((0...n_players).collect)
      if params.has_key?(:missions)
        params[:missions].each do |n|
          r.choose_results.push([n])
        end
      end
      r.choose_results.push(*((0..41).collect.reverse.collect{ |n| [n] }))
    end
    players.each do |player|
      $state.with_person(player) do |p|
        p.command('b�rja')
      end
    end
    players.each do |player|
      $state.with_person(player) do |p|
        p.clear_messages
      end
    end
    $state.with_first_game_and_admin do |g, a|
      g.request(params.merge(:person => a, :type => :set_turn_queue, :names => players))
    end
    return players
  end

  def setup_map(map_str)
    matches = map_str.scan(/[#XO%@�] ?\d+/)
    $state.with_first_game do |g|
      matches.zip(g.map.countries).each do |match, country|
        player_no = TextInterface::INITIALS.index(match[0..0])
        country.owner = g.players[player_no]
        country.armies = match[1..-1].to_i
      end
    end
  end
end

