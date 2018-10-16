# coding: utf-8
#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++

class String
  alias_method :old_downcase, :downcase
  def downcase
    self.old_downcase.tr('ÅÄÖÉ', 'åäöé')
  end
end

module Enumerable
  def swedish(word = "och")
    words = to_a
    if length > 1
      [words[0..-2].join(', '), words[-1]].join(' %s ' % word)
    else
      return self[0]
    end
  end
end

class Integer
  SWEDISH_NUMBERS = ["inga", nil, "två", "tre", "fyra",
    "fem", "sex", "sju", "åtta", "nio",
    "tio", "elva", "tolv", "tretton", "fjorton",
    "femton", "sexton", "sjutton", "arton", "nitton"]

  SWEDISH_ONE = ["en", "ett"]

  SWEDISH_TENS = ["tjugo", "trettio", "fyrtio", "femtio",
    "sextio", "sjuttio", "åttio", "nittio"]

  SWEDISH_ORDINALS = ["första", "andra", "tredje", "fjärde", "femte",
    "sjätte", "sjunde", "åttonde", "nionde", "tionde",
    "elfte", "tolfte", "trettonde", "fjortonde", "femtonde",
    "sextonde", "sjuttonde", "artonde", "nittonde"]

  def swedish(params = {})
    if self < 1000
      return self.small_swedish(params)
    elsif self < 1000000000
      millions = self / 1000000
      thousands = (self % 1000000) / 1000
      rest = self % 1000
      result = ""
      if millions > 0
        if params[:ordinal] and not (thousands or rest)
          result << millions.small_swedish + " miljonte"
        else
          result << millions.swedish_quantity("miljon ", "miljoner ", :long => true)
        end
      end
      if thousands > 0
        if params[:ordinal] and not rest
          result << thousands.small_swedish(:neutrum => true) + "tusende"
        else
          result << thousands.small_swedish(:neutrum => true) + "tusen "
        end
      end
      if rest > 0
        result << rest.small_swedish(params)
      end
      return result
    elsif params[:ordinal]
      if self % 10 == 1 or self % 10 == 2
        return "%d:a" % self
      else
        return "%d:e" % self
      end
    else
      return "%d" % self
    end
  end

  def swedish_quantity(singular, plural, params = {})
    if params[:short] or self > 19 and not params[:long]
      number_string = "%d" % self
    else
      number_string = self.small_swedish(params)
    end

    if self == 1
      unit_string = singular
    else
      unit_string = plural
    end

    return "%s %s" % [number_string, unit_string]
  end

  protected

  def small_swedish(params = {})
    if self == 0 and params[:ordinal]
      return "de"
    elsif self == 1 and not params[:ordinal]
      return SWEDISH_ONE[params[:neutrum] ? 1 : 0]
    elsif self < 20
      return params[:ordinal] ? SWEDISH_ORDINALS[self-1] : SWEDISH_NUMBERS[self]
    elsif self < 1000
      hundreds = self / 100
      tens = (self % 100) / 10
      ones = self % 10
      result = ""
      ordinal_suffix = ""
      if hundreds > 0
        result << hundreds.small_swedish(:neutrum => true) + "hundra"
        ordinal_suffix = "de"
      end
      if tens > 1
        result << SWEDISH_TENS[tens-2]
        ordinal_suffix = "nde"
        if ones
          result += ones.small_swedish(params.merge({:neutrum => false}))
          ordinal_suffix = ""
        end
      elsif tens > 0 or ones > 0
        result += (tens * 10 + ones).small_swedish(params)
        ordinal_suffix = ""
      end
      if params[:ordinal]
        return result + ordinal_suffix
      else
        return result
      end
    else
      return "%d" % self
    end
  end
end

