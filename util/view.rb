#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++
module Enumerable
  def list_view(width = 70)
    result = ''
    each do |e|
      result << '  ' << e.to_s << "\n"
    end
    result
  end

  def max_length
    collect{ |e| e.length }.max || 0
  end

  def column_list_view(width = 70, spacing = 2)
    for rows in 1..length do
      total_width = 0
      columns = []
      0.step(length, rows) do |n|
        column = self[n, rows]
        columns << column
        total_width += column.max_length || 0
      end
      total_width += spacing * (columns.length - 1)
      if total_width <= width
        return lists_to_columns(columns, spacing)
      end
    end
    return self.list_view
  end

  private

  def lists_to_columns(columns, spacing = 2)
    widths = columns.collect{ |c| c.max_length + spacing }
    columns[0].zip(*columns[1..-1]).collect do |l|
      line = ''
      l.each_with_index do |entry, i|
        line << (entry || '').ljust(widths[i])
      end
      line.strip
    end.list_view
  end
end
