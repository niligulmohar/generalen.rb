# coding: utf-8

require 'minitest/autorun'
require_relative '../util/random'
require_relative '../util/swedish'
require_relative '../generalen/state'
require_relative '../generalen/game'
require_relative '../generalen/person'
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

class BigTestCase < Minitest::Test

  TEST_STATE_FILE_NAME = 'GENERALEN.test.STATE'

  def setup
    @random = Randomness::TestSource.new
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

  def test_create_done
    $state.with_person(:Pelle) do |p|
      p.command('ny')
      assert_match( /Du har skapat Första partiet/, p.get )
      assert_match( /Inställningar för/, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
      p.command('kl')
      assert_match( /Spelet har inte startat/, p.get )
    end
  end

  def test_create_settings_start_twoplayer_surrender
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
      r.choose_results.push(*((0..41).reverse_each.map{ |n| [n] }))
      r.randrange_results.push(4, 5, 6, 1, 2)
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
      assert_match( /Du tilldelas fjorton länder.*Du har 26 arméer/m, p.get )
      p.command('karta')
      assert_match( /~/, p.get )
      p.command('pl 3 ö a 3 arg 3 indo 3 bra 3 sia 3 norda 3 kin västeu 3 v f 2')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Säg "klar"/, p.get )
      p.command('kl')
      assert_match( /Pelle är klar/, p.get )
      assert_match( /Väntar på.*Svenzuno/m, p.get )
    end
    $state.with_person(:Svenzuno) do |p|
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Svenzuno.*Pelle/m, p.get )
      assert_match( /Du tilldelas fjorton länder.*Du har 26 arméer/m, p.get )
      assert_match( /Pelle är klar/, p.get )
      assert_match( /Väntar på.*Svenzuno/m, p.get )
      p.command('pl v a 3 mada 3 kon 3 per 3 indi 3 mel 3 sydeu 3 jap 3 mon 2')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Säg "klar"/, p.get )
      p.command('kl')
      assert_match( /Svenzuno är klar/, p.get )
      assert_match( /Det är din tur/, p.get )
      assert_match( /Du får inga arméer första rundan/, p.get )
      p.command('anf n g från v a med 3')
      assert_match( /Svenzuno.*anfaller.*Neutral.*6...5...4.*2...1/m, p.get )
      assert_match( /Svenzuno erövrar Nya Guinea/m, p.get )
      p.command('kap!')
      assert_match( /Svenzuno har kapitulerat/, p.get )
      assert_match( /Pelle har vunnit/, p.get )
      assert_nil( p.get )
    end
    $state.with_person(:Pelle) do |p|
      assert_match( /Svenzuno är klar/, p.get )
      assert_match( /Turen övergår till Svenzuno/, p.get )
      assert_match( /Svenzuno.*anfaller.*Neutral.*6...5...4.*2...1/m, p.get )
      assert_match( /Svenzuno erövrar Nya Guinea/m, p.get )
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
      r.choose_results.push(*((0..41).reverse_each.map{ |n| [n] }))
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
      p.command('fl 3 från egy till östa')
      assert_match( /Svenzuno flyttar tre arméer från/, p.get )
      p.command('fl 2 från östa till kon')
      assert_match( /Svenzuno flyttar två arméer från/, p.get )
      p.command('fl 1 från östa till kon')
      assert_match( /Svenzuno flyttar en armé från/, p.get )

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
      assert_match( /Svenzuno flyttar tre arméer från/, p.get )
      assert_match( /Svenzuno flyttar två arméer från/, p.get )
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
      assert_match( /Svenzuno flyttar tre arméer från/, p.get )
      assert_match( /Svenzuno flyttar två arméer från/, p.get )
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
      p.command('byt')
      assert_match( /Användn/, p.get )
      assert_match( /Kortkombinationer/, p.get )
      assert_match( /3xA/, p.get )
      assert_match( /Du har följande kort.*C/, p.get )
      p.command('byt a a b')
      assert_match( /Det är inte en giltig kortkombination/, p.get )
      p.command('byt a b c')
      assert_match( /Du har inte alla dom korten/, p.get )
      p.command('pl kon 5')
      assert_match( /Du har placerat ut/, p.get )
      assert_match( /Är du klar/, p.get )
      p.command('an norda fr kon med 6!')
      assert_match( /Svenzuno placerar ut/, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno.*anfaller.*Stina/m, p.get )
      assert_match( /Svenzuno erövrar Nordafrika/m, p.get )
      p.command('kort a b c')
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
      p.command('by')
      assert_match( /exempel/, p.get )
      assert_match( /Kortkombinationer/, p.get )
      assert_match( /3xA/, p.get )
      assert_match( /.A. .B. .C./, p.get )
      p.command('ko a b c')
      assert_match( /Stina får tio extra arméer för följande kort/, p.get )
      p.command('ko')
      assert_match( /Kortkombinationer/, p.get )
      assert_match( /3xA/, p.get )
      assert_match( /Du har inga kort/, p.get )
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
      2.times do
        r.choose_results.push([0, 1])
        r.choose_results.push(*((0..41).reverse_each.map{ |n| [n] }))
      end
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
      assert_match( /Du tilldelas fjorton länder.*Du har 26 arméer/m, p.get )
    end
    # Byte från öppet parti till parti där första placering börjar
    $state.with_person(:Stina) do |p|
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Första partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas fjorton länder.*Du har 26 arméer/m, p.get )
      assert_match( /Du är nu aktiv i Första partiet/, p.get )
    end
    $state.with_person(:Pelle) do |p|
      p.command('gå an')
      assert_match( /Du är nu aktiv i Andra partiet/, p.get )
      p.command('bö')
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Andra partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas fjorton länder.*Du har 26 arméer/m, p.get )
    end
    # Inget byte från ett parti där första placeringen pågår
    $state.with_person(:Stina) do |p|
      assert_match( /Pelle är redo/, p.get )
      assert_match( /Andra partiet har börjat!/, p.get )
      assert_match( /Turordningen.*Pelle.*Stina/m, p.get )
      assert_match( /Du tilldelas fjorton länder.*Du har 26 arméer/m, p.get )
      assert_nil( p.get )
    end
    # Byte till ett parti där första placeringen pågår, när man är klar
    $state.with_person(:Stina) do |p|
      p.command('pl 3 ö a 3 arg 3 indo 3 bra 3 sia 3 norda 3 kin västeu 3 v f 2')
      #p.command('pla 3 ö a 3 syda 3 mada 3 indo 3 östa 2 peru 2 sia')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Säg "klar"/, p.get )
      p.command('kl')
      assert_match( /Stina är klar/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
      assert_match( /Du är nu aktiv i Andra partiet/, p.get )
    end
    $state.with_person(:Stina) do |p|
      p.command('pl 3 ö a 3 arg 3 indo 3 bra 3 sia 3 norda 3 kin västeu 3 v f 2')
      #p.command('pla 3 ö a 3 syda 3 mada 3 indo 3 östa 2 peru 2 sia')
      assert_match( /Du har placerat/, p.get )
      assert_match( /Säg "klar"/, p.get )
      p.command('kl')
      assert_match( /Stina är klar/, p.get )
      assert_match( /Väntar på.*Pelle/m, p.get )
    end
  end

  def test_winning_specific_continents
    players = start_game(:missions => [0, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Erövra Asien och Sydamerika/, g.players.first.mission.swedish )
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
      p.command('anfall venezuela från peru med 1')
      assert_match( /Pelle.*anfaller.*Kalle/m, p.get )
      assert_match( /Pelle erövrar Venezuela/m, p.get )
      assert_match( /Pelle har vunnit.*!/m, p.get )
    end
  end

  def test_winning_specific_continents_plus_one
    players = start_game(:missions => [5, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Erövra Europa och Australien, samt ytterligare en valfri kontinent/, g.players.first.mission.swedish )
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
      p.command('anfall indonesien från nya guinea med 1')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_n_countries
    players = start_game(:missions => [7, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Erövra 24 valfria länder/, g.players.first.mission.swedish )
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
      p.command('anfall nordafrika från egypten med 1')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_n_countries_n_armies_by_attacking
    players = start_game(:missions => [6, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Erövra 18 valfria länder och placera minst 2 arméer i varje land/, g.players.first.mission.swedish )
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
      p.command('anfall ukraina från ural med 2')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_n_countries_n_armies_by_moving
    players = start_game(:missions => [6, 0, 0])
    $state.with_first_game do |g|
      assert_match( /Erövra 18 valfria länder och placera minst 2 arméer i varje land/, g.players.first.mission.swedish )
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
      p.command('flytta 1 från ural till ukraina')
    end
    $state.with_first_game do |g|
      assert(g.players.first.winner)
      assert(g.finished)
    end
  end

  def test_winning_n_countries_n_armies_by_placement
    players = start_game(:missions => [6, 0, 0], :armies_for_placement => 1)
    $state.with_first_game do |g|
      assert_match( /Erövra 18 valfria länder och placera minst 2 arméer i varje land/, g.players.first.mission.swedish )
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
      assert_match( /Utplåna Kalle. Om du är Kalle/, g.players.first.mission.swedish )
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
      p.command('anfall ukraina från afghanistan med 1')
      assert_match( /Pelle.*anfaller.*Kalle/m, p.get )
      assert_match( /Pelle erövrar Ukraina/m, p.get )
      assert_match( /Kalle är besegrad/m, p.get )
      assert_match( /Pelle har vunnit.*!/m, p.get )
    end
  end

  def test_winning_fallback_mission
    players = start_game(:missions => [0, 9, 0])
    $state.with_first_game do |g|
      assert_match( /Utplåna Olle. Om du är Olle/, g.players[1].mission.swedish )
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
      p.command('anfall ukraina från ural med 1')
      assert_match( /Pelle.*anfaller.*Olle/m, p.get )
      assert_match( /Pelle erövrar Ukraina/m, p.get )
      assert_match( /Olle är besegrad/m, p.get )
      assert_match( /Du övertar följande kort.*A.*A/m, p.get )
      p.command('kort')
      assert_match( /Kortkombinationer/, p.get )
      assert_match( /3xA/, p.get )
      assert_match( /.A. .A./, p.get )
      p.command('klar')
      assert_match( /Du får ett kort.*A/, p.get )
      assert_match( /Turen övergår till Kalle/, p.get )
    end
    $state.with_person(:Kalle) do |p|
      assert_match( /Pelle.*anfaller.*Olle/m, p.get )
      assert_match( /Pelle erövrar Ukraina/m, p.get )
      assert_match( /Olle är besegrad/m, p.get )
      assert_match( /Pelle övertar två kort/m, p.get )
      assert_match( /Pelle får ett kort/m, p.get )
      assert_match( /Det är din tur/m, p.get )
      assert_match( /Du får inga arméer första rundan/, p.get )
      p.command('anfall storbritannien från västeuropa med 1')
      assert_match( /Kalle.*anfaller.*Pelle/m, p.get )
      assert_match( /Kalle erövrar Storbritannien/m, p.get )
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
      p.command('anfall arg från bra med 1')
      assert_match( /Pelle.*anfaller.*Kalle/m, p.get )
      assert_match( /Pelle erövrar Argentina/m, p.get )
      assert_match( /Kalle är besegrad/m, p.get )
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
      p.command('sätt speltyp=världsdominans') unless params.has_key?(:missions)
    end
    players[1..-1].each do |player|
      $state.with_person(player) do |p|
        p.command('deltag')
      end
    end
    $state.with_random_source do |r|
      r.choose_results.push((0...n_players).to_a)
      if params.has_key?(:missions)
        params[:missions].each do |n|
          r.choose_results.push([n])
        end
      end
      r.choose_results.push(*((0..41).reverse_each.map{ |n| [n] }))
    end
    players.each do |player|
      $state.with_person(player) do |p|
        p.command('börja')
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
    matches = map_str.scan(/[#XO%@¤] ?\d+/)
    $state.with_first_game do |g|
      matches.zip(g.map.countries).each do |match, country|
        player_no = TextInterface::INITIALS.index(match[0..0])
        country.owner = g.players[player_no]
        country.armies = match[1..-1].to_i
      end
    end
  end
end

