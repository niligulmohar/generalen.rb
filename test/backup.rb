require 'util/backup'
require 'fileutils'
require 'test/unit'

class BackupTestCase < Test::Unit::TestCase
  FILENAME = 'BACKUPTESTCASE'
  class << FILENAME
    def n(n)
      '%s.%d' % [self, n]
    end
  end
  def test_with_rotation
    assert(!File::exists?(FILENAME))
    (1..3).each { |n| assert(!File::exists?(FILENAME.n(n))) }

    f = File.new(FILENAME, 'w')
    f.write('Tomte')
    f.close
    assert_equal 'Tomte', File::read(FILENAME)
    Backup::with_rotation(FILENAME)
    assert_equal 'Tomte', File::read(FILENAME)
    assert_equal 'Tomte', File::read(FILENAME.n(1))

    f = File.new(FILENAME, 'a')
    f.write('Potatis')
    f.close
    Backup::with_rotation(FILENAME)
    assert_equal 'TomtePotatis', File::read(FILENAME)
    assert_equal 'TomtePotatis', File::read(FILENAME.n(1))
    assert_equal 'Tomte', File::read(FILENAME.n(2))

    f = File.new(FILENAME, 'a')
    f.write('Bravo')
    f.close
    Backup::with_rotation(FILENAME)
    assert_equal 'TomtePotatisBravo', File::read(FILENAME)
    assert_equal 'TomtePotatisBravo', File::read(FILENAME.n(1))
    assert_equal 'TomtePotatis', File::read(FILENAME.n(2))
    assert_equal 'Tomte', File::read(FILENAME.n(3))

    FileUtils::rm(FILENAME)
    (1..3).each { |n| FileUtils::rm(FILENAME.n(n)) }
    assert(!File::exists?(FILENAME))
    (1..3).each { |n| assert(!File::exists?(FILENAME.n(n))) }
  end
end
