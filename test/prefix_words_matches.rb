require 'test/unit'
require 'util/prefix_words_matches'
require 'set'

class PrefixTestCase < Test::Unit::TestCase
  def setup
    @foo2 = %w{ foo bar }
    @foo3 = %w{ foo bar gazonk }
    @fredrika = %w{ fredrika bremer }
    @names = ({ @foo2 => nil,
                @foo3 => nil,
                @fredrika => nil })
  end
  def test_komexpand_empty
    assert_equal([ [ @foo2, [] ],
                   [ @foo3, [] ],
                   [ @fredrika, [] ] ].to_set,
                 @names.prefix_words_matches([]).to_set)
  end
  def test_komexpand_1word
    assert_equal([ [ @foo2, [] ],
                   [ @foo3, [] ],
                   [ @fredrika, [] ] ].to_set,
                 @names.prefix_words_matches(%w{ f }).to_set)
    assert_equal([ [ @foo2, [] ],
                   [ @foo3, [] ] ].to_set,
                 @names.prefix_words_matches(%w{ fo }).to_set)
    assert_equal([ [ @fredrika, [] ] ].to_set,
                 @names.prefix_words_matches(%w{ fr }).to_set)
    assert_equal(Set.new,
                 @names.prefix_words_matches(%w{ x }).to_set)
    assert_equal([ [ @foo2, ['x'] ],
                   [ @foo3, ['x'] ],
                   [ @fredrika, ['x'] ] ].to_set,
                 @names.prefix_words_matches(%w{ x }, true).to_set)
  end
  def test_komexpand_2word
    assert_equal([ [ @foo2, [] ],
                   [ @foo3, [] ],
                   [ @fredrika, [] ] ].to_set,
                 @names.prefix_words_matches(%w{ f b }).to_set)
    assert_equal([ [ @foo2, [] ],
                   [ @foo3, [] ] ].to_set,
                 @names.prefix_words_matches(%w{ f ba }).to_set)
    assert_equal([ [ @fredrika, [] ] ].to_set,
                 @names.prefix_words_matches(%w{ f br }).to_set)
  end
  def test_foo2_complete
    assert_equal([ [ @foo2, [] ] ].to_set,
                 @names.prefix_words_matches(%w{ foo bar }).to_set)
  end
  def test_foo2_complete_remainder
    assert_equal([ [ @foo2, ['gurk'] ] ].to_set,
                 @names.prefix_words_matches(%w{ foo bar gurk }).to_set)
  end
  def test_foo3_complete
    assert_equal([ [ @foo3, [] ] ].to_set,
                 @names.prefix_words_matches(%w{ foo bar gaz }).to_set)
  end
  def test_fredrika_prefix_remainder
    assert_equal([ [ @fredrika, ['gurk'] ] ].to_set,
                 @names.prefix_words_matches(%w{ fre gurk }).to_set)
  end
  def test_komexpand_remainder
    assert_equal([ [ @foo2, ['gurk', 'moj'] ],
                   [ @foo3, ['gurk', 'moj'] ],
                   [ @fredrika, ['gurk', 'moj'] ] ].to_set,
                 @names.prefix_words_matches(%w{ f gurk moj }).to_set)
  end
end
