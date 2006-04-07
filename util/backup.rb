#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++
require 'fileutils'

module Backup
  def Backup.with_rotation(filename)
    class << filename
      def n(n)
        '%s.%d' % [self, n]
      end
    end
    n = 0
    while File::exists?(filename.n(n+1))
      n += 1
    end
    n.downto(1) do |i|
      FileUtils.move(filename.n(i), filename.n(i+1))
    end
    if File::exists?(filename)
      FileUtils.copy(filename, filename.n(1))
    end
  end
end
