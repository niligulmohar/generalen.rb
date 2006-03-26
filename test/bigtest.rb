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
      assert_match( /Du har skapat Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
    end
    @names[1..5].each do |name|
      $state.with_person(name.to_sym) do |p|
        p.command('de')
        assert_match( /Du har gått med i Första partiet/, p.get )
        assert_match( /Inställningar för/, p.get )
        assert_match( /Deltagare i/, p.get )
        assert_match( /Du är nu aktiv i Första partiet/, p.get )
      end
    end
    $state.with_person(:Svenzuno) do |p|
      p.command('de')
      assert_match( /Första partiet är fullt!/, p.get )
    end
    @names[0..5].each_with_index do |name, i|
      $state.with_person(name.to_sym) do |p|
        (i+1).upto(5) do |n|
          assert_match( /#{@names[n]} har gått med i Första partiet/, p.get )
          assert_match( /Skriv "börja"/, p.get )
        end
      end
    end
    $state.with_person(:Pelle) do |p|
      p.command('säg Tomtar gillar potatis')
    end
    @names[0..5].each_with_index do |name, i|
      $state.with_person(name.to_sym) do |p|
        assert_match( /Pelle.*Första partiet.*Tomtar gillar potatis/m, p.get )
        p.command('lä')
        0.upto(i) do |n|
          assert_match( /#{@names[n]} har lämnat Första partiet/, p.get )
          assert_match( /Skriv "börja"/, p.get ) if n < 4
        end
        if i == 5
          assert_match( /Första partiet har upphört/, p.get )
        end
        assert_nil( p.get )
      end
    end
  end

  def test_create_settings_start_surrender
    $state.with_person(:Pelle) do |p|
      p.command('ny')
      assert_match( /Du har skapat Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
      p.command('sät spe = v')
      assert_match( /Världsdominans/, p.get )
      p.command('bö')
      assert_match( /Det krävs mer än en/, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      p.command('de')
      assert_match( /Du har gått med i Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
      p.command('bö')
      assert_match( /Svenzuno är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Svenzuno har gått med i Första partiet/, p.get )
      assert_match( /Skriv "börja"/, p.get )
      assert_match( /Svenzuno är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
      p.command('sät spe = v')
      assert_match( /Världsdominans/, p.get )
      assert_match( /Skriv "börja"/, p.get )
      p.command('bö')
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Väntar på.*Svenzuno/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Världsdominans/, p.get )
      assert_match( /Du måste skriva "börja" igen/, p.get )
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Väntar på.*Svenzuno/m, p.get )
      p.command('sät dra = 1')
      assert_match( /en minut/, p.get )
      assert_match( /Du måste skriva "börja" igen/, p.get )
      p.command('bö')
      assert_match( /Svenzuno är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
    end
    $state.with_random_source do |r|
      r.choose_results.push([1, 0])
      r.choose_results.push(*((0..41).collect.reverse.collect{ |n| [n] }))
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /en minut/, p.get )
      assert_match( /Du måste skriva "börja" igen/, p.get )
      assert_match( /Svenzuno är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
      p.command('bö')
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle/m, p.get )
      assert_match( /Du tilldelas 21 länder.*Du har nitton arméer/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle/m, p.get )
      assert_match( /Du tilldelas 21 länder.*Du har nitton arméer/m, p.get )
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
      assert_match( /Du har skapat Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      p.command('de')
      assert_match( /Du har gått med i Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
      p.command('bö')
      assert_match( /Det krävs minst tre/, p.get )
    end
    $state.with_person(:Stina) do |p|
      p.command('de')
      assert_match( /Du har gått med i Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
      p.command('bö')
      assert_match( /Stina är redo/, p.get )
      assert_match( /Väntar på.*Pelle.*Svenzuno/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Stina har gått med i Första partiet/, p.get )
      assert_match( /Skriv "börja"/, p.get )
      assert_match( /Stina är redo/, p.get )
      assert_match( /Väntar på.*Pelle.*Svenzuno/m, p.get )
      p.command('bö')
      assert_match( /Svenzuno är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
    end
    $state.with_random_source do |r|
      r.choose_results.push([1, 0, 2], [1], [7], [4])
      r.choose_results.push(*((0..41).collect.reverse.collect{ |n| [n] }))
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Svenzuno har gått med i Första partiet/, p.get )
      assert_match( /Skriv "börja"/, p.get )
      assert_match( /Stina har gått med i Första partiet/, p.get )
      assert_match( /Skriv "börja"/, p.get )
      assert_match( /Stina är redo/, p.get )
      assert_match( /Väntar på.*Pelle.*Svenzuno/m, p.get )
      assert_match( /Svenzuno är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
      p.command('bö')
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle/m, p.get )
      assert_match( /Ditt uppdrag.*Erövra Asien och Afrika/, p.get )
      assert_match( /Du tilldelas fjorton länder.*Du har 21 arméer/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle.*Stina/m, p.get )
      assert_match( /Ditt uppdrag.*Utplåna Pelle/, p.get )
      assert_match( /Du tilldelas fjorton länder.*Du har 21 arméer/m, p.get )
      p.command('pl ven 3 n g 3 syda 3 östa 3')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Du har nio arméer kvar/, p.get )
      p.command('pl egy -1')
      assert_match( /För få arméer/, p.get )
      assert_match( /Du har nio arméer kvar/, p.get )
      p.command('pl egy 5')
      assert_match( /För många arméer/, p.get )
      assert_match( /Du har nio arméer kvar/, p.get )
      p.command('pl egy = 3, 3 i cen och 3 i afg')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Säg "klar"/, p.get )
      p.command('kl')
      assert_match( /Svenzuno är klar/, p.get )
      assert_match( /Väntar på.*Pelle.*Stina/m, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Svenzuno är klar/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
      p.command('pl 3 v a 3 mada 3 kon 3 per 3 indi 3 mel 3 syde 3 jap')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Du har placerat ut tre arméer mer.*Åtgärda/, p.get )
      p.command('pl -3 jap')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Säg "klar"/, p.get )
      p.command('kl')
      assert_match( /Pelle är klar/, p.get )
      assert_match( /Väntar på.*Stina/m, p.get )
    end
    $state.with_person(:Stina) do |p|
      assert_match( /Svenzuno är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle.*Stina/m, p.get )
      assert_match( /Ditt uppdrag.*Erövra Europa och Australien/, p.get )
      assert_match( /Du tilldelas fjorton länder.*Du har 21 arméer/m, p.get )
      assert_match( /Svenzuno är klar/, p.get )
      assert_match( /Väntar på.*Pelle.*Stina/m, p.get )
      assert_match( /Pelle är klar/, p.get )
      assert_match( /Väntar på.*Stina/m, p.get )
      p.command('pl 3 ö a 3 arg 3 indo 3 bra 3 sia 3 norda 3 kin')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Säg "klar"/, p.get )
      p.command('kl')
      assert_match( /Stina är klar/, p.get )
      assert_match( /Turen övergår till Svenzuno/, p.get )
    end
    $state.with_random_source do |r|
      r.randrange_results.push(4, 5, 6, 1, 2)
      r.randrange_results.push(3, 2, 1, 3, 2)
      r.randrange_results.push(6, 1, 1)
      r.randrange_results.push(6, 1)
      r.randrange_results.push(39)
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Pelle är klar/, p.get )
      assert_match( /Väntar på.*Stina/m, p.get )
      assert_match( /Stina är klar/, p.get )
      assert_match( /Det är din tur/, p.get )
      assert_match( /Du får inga arméer första rundan/, p.get )
      p.command('an kon fr syda med 0')
      assert_match( /Det är ett fånigt antal arméer att anfalla med/, p.get )
      p.command('an kon fr syda med 666')
      assert_match( /Du har inte så många arméer tillgängliga/, p.get )
      p.command('an kon fr syda med 3')
      assert_match( /Svenzuno.*anfaller.*Pelle.*6...5...4.*2...1/m, p.get )
      p.command('an ig')
      assert_match( /Svenzuno.*anfaller.*Pelle.*3...2...1.*3...2/m, p.get )
      p.command('an ig')
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1...1/m, p.get )
      p.command('an ig')
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1/m, p.get )
      assert_match( /Svenzuno erövrar Kongo/m, p.get )
      p.command('pl östa -1')
      assert_match( /Du får inte placera arméer eller använda kort, för du har redan anfallit/, p.get )
      p.command('fl 1 från östa till kon')
      assert_match( /Svenzuno flyttar en armé från/, p.get )
      p.command('fl 1 från syda till kon')
      assert_match( /Du får inte flytta så många arméer därifrån/, p.get )
      p.command('fl 0')
      assert_match( /Det är ett fånigt antal arméer att flytta/, p.get )
      p.command('anf Norda från kon med 2')
      assert_match( /Du får inte anfalla, för du har redan flyttat/, p.get )
      p.command('kl')
      assert_match( /Du får ett kort.*C/, p.get )
      assert_match( /Turen övergår till Pelle/, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Stina är klar/, p.get )
      assert_match( /Turen övergår till Svenzuno/, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6...5...4.*2...1/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*3...2...1.*3...2/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1...1/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1/m, p.get )
      assert_match( /Svenzuno erövrar Kongo/m, p.get )
      assert_match( /Svenzuno flyttar en armé från/, p.get )
      assert_match( /Svenzuno får ett kort/, p.get )
      assert_match( /Det är din tur/, p.get )
      assert_match( /Du får inga arméer första rundan/, p.get )
      p.command('kl')
      assert_match( /Varning/, p.get )
      p.command('kl')
      assert_match( /Turen övergår till Stina/, p.get )
    end
    $state.with_person(:Stina) do |p|
      assert_match( /Svenzuno.*anfaller.*Pelle.*6...5...4.*2...1/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*3...2...1.*3...2/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1...1/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Pelle.*6.*1/m, p.get )
      assert_match( /Svenzuno erövrar Kongo/m, p.get )
      assert_match( /Svenzuno flyttar en armé från/, p.get )
      assert_match( /Svenzuno får ett kort/, p.get )
      assert_match( /Turen övergår till Pelle/, p.get )
      assert_match( /Det är din tur/, p.get )
      assert_match( /Du får inga arméer första rundan/, p.get )
      p.command('kl')
      assert_match( /Varning/, p.get )
      p.command('kl')
      assert_match( /Turen övergår till Svenzuno/, p.get )
    end
    $state.with_random_source do |r|
      r.randrange_results.push(6, 6, 6, 1, 1)
      r.randrange_results.push(6, 6, 6, 1, 1)
      r.randrange_results.push(0)
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Turen övergår till Stina/, p.get )
      assert_match( /Det är din tur/, p.get )
      assert_match( /Du har fem nya arméer/, p.get )
      p.command('ko')
      assert_match( /Användn/, p.get )
      assert_match( /Du har följande kort.*C/, p.get )
      assert_match( /Ditt uppdrag.*Utplåna Pelle/, p.get )
      p.command('ko a a b')
      assert_match( /Det är inte en giltig kortkombination/, p.get )
      p.command('ko a b c')
      assert_match( /Du har inte alla dom korten/, p.get )
      p.command('pl kon 5')
      assert_match( /Du har placerat ut/, p.get )
      assert_match( /Är du klar/, p.get )
      p.command('an norda fr kon med 6!')
      assert_match( /Svenzuno placerar ut/, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno erövrar Nordafrika/m, p.get )
      p.command('ko a b c')
      assert_match( /Du får inte placera arméer eller använda kort, för du har redan anfallit/, p.get )
      p.command('kl')
      assert_match( /Du får ett kort.*A/, p.get )
      assert_match( /Turen övergår till Pelle/, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Turen övergår till Svenzuno/, p.get )
      assert_match( /Svenzuno placerar ut/, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno erövrar Nordafrika/m, p.get )
      assert_match( /Svenzuno får ett kort/, p.get )
      assert_match( /Det är din tur/, p.get )
      assert_match( /Du har fyra nya arméer/, p.get )
      p.command('kl')
      assert_match( /Du får inte avsluta din tur/, p.get )
      p.command('pl v a 4')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Är du klar/, p.get )
      p.command('kl')
      assert_match( /Pelle placerar ut/, p.get )
      assert_match( /Turen övergår till Stina/, p.get )
    end
    $state.with_person(:Stina) do |p|
      assert_match( /Svenzuno placerar ut/, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno erövrar Nordafrika/m, p.get )
      assert_match( /Svenzuno får ett kort/, p.get )
      assert_match( /Turen övergår till Pelle/, p.get )
      assert_match( /Pelle placerar ut/, p.get )
      assert_match( /Det är din tur/, p.get )
      assert_match( /Du har fyra nya arméer/, p.get )
      [ :a, :b, :c ].each do |c|
        p.current_game.people_players[p].recieve_card(c)
      end
      p.command('ko')
      assert_match( /exempel/, p.get )
      assert_match( /.A. .B. .C./, p.get )
      assert_match( /uppdrag/, p.get )
      p.command('ko a b c')
      assert_match( /Stina får tio extra arméer för följande kort/, p.get )
      p.command('ko')
      assert_match( /exempel/, p.get )
      assert_match( /Inga kort/, p.get )
      assert_match( /uppdrag/, p.get )
    end
  end

  def test_multiple_games
    $state.with_person(:Pelle) do |p|
      p.command('ny')
      assert_match( /Du har skapat Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
      p.command('sät spe=vär')
      assert_match( /Världsdominans/, p.get )
    end
    $state.with_person(:Stina) do |p|
      p.command('de')
      assert_match( /Du har gått med i Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
      p.command('bö')
      assert_match( /Stina är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Stina har gått med i Första partiet/, p.get )
      assert_match( /Skriv "börja"/, p.get )
      assert_match( /Stina är redo att börja i Första partiet/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
      p.command('ny')
      assert_match( /Du har skapat Andra partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Du är nu aktiv i Andra partiet/, p.get )
      p.command('sät spe=vär')
      assert_match( /Världsdominans/, p.get )
    end
    $state.with_person(:Stina) do |p|
      p.command('de')
      assert_match( /Du har gått med i Andra partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Deltagare i/, p.get )
      assert_match( /Du är nu aktiv i Andra partiet/, p.get )
      p.command('bö')
      assert_match( /Stina är redo/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
    end
    $state.with_random_source do |r|
      r.choose_results.push([0, 1])
      r.choose_results.push(*((0..41).collect.reverse.collect{ |n| [n] }))
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Stina har gått med i Andra partiet/, p.get )
      assert_match( /Skriv "börja"/, p.get )
      assert_match( /Stina är redo att börja i Andra partiet/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
      p.command('gå fö')
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
      p.command('bö')
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas 21 länder.*Du har nitton arméer/m, p.get )
    end
    $state.with_person(:Stina) do |p|
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas 21 länder.*Du har nitton arméer/m, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
    end
  end

  def teardown
    $state = nil
    FileUtils::rm(TEST_STATE_FILE_NAME);
  end
end

