# -*- coding: iso-8859-1 -*-

require 'test/unit'
require 'util/random'
require 'util/swedish'
require 'generalen/state'
require 'generalen/game'
require 'generalen/person'
require 'fileutils'


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

  def test_create_settings_start_surrender
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
      assert_match( /Du tilldelas 21 l�nder.*Du har nitton arm�er/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle/m, p.get )
      assert_match( /Du tilldelas 21 l�nder.*Du har nitton arm�er/m, p.get )
      p.command('kap!')
      assert_match( /Svenzuno har kapitulerat/, p.get )
      assert_match( /Pelle har vunnit/, p.get )
      assert_nil( p.get )
    end
    $state.with_person(:Pelle) do |p|
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
      p.command('kl')
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
      r.choose_results.push([0, 1])
      r.choose_results.push(*((0..41).collect.reverse.collect{ |n| [n] }))
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
      assert_match( /Du tilldelas 21 l�nder.*Du har nitton arm�er/m, p.get )
    end
    $state.with_person(:Stina) do |p|
      assert_match( /Pelle �r redo/, p.get )
      assert_match( /F�rsta partiet har b�rjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas 21 l�nder.*Du har nitton arm�er/m, p.get )
      assert_match( /Du �r nu aktiv i F�rsta partiet/, p.get )
    end
  end

  def teardown
    $state = nil
    FileUtils::rm(TEST_STATE_FILE_NAME);
  end
end

