# coding: utf-8
#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++
require_relative '../util/swedish'

class Hash
  def prefix_words_matches(words, allow_match_all = false)
    perfect = keys.select{ |k| k.collect{ |w| w.downcase } == words.collect{ |w| w.downcase } }
    if perfect.length == 1
      return [[perfect.first, []]]
    end
    old_subset = keys
    subset = []
    words.each_with_index do |w, i|
      subset = old_subset.select { |cmp| cmp[i] and cmp[i].downcase == w.downcase }
      if subset.empty?
        subset = old_subset.select { |cmp| cmp[i] and cmp[i].downcase.index(w.downcase) == 0 }
      end
      if subset.empty?
        results = old_subset.collect{|cmp| [cmp, words[i..-1]]}
        short_results = results.select { |cmp| cmp.first.length <= i }
        if i == 0 and not allow_match_all
          return []
        elsif not short_results.empty?
          return short_results
        else
          return results
        end
      end
      old_subset = subset
    end
    return old_subset.collect{|cmp| [cmp, []]}#.select { |cmp| cmp.length <= words.length }
  end
end

module Enumerable
  def name_hash
    result = {}
    each do |e|
      result[e.name.strip.split] = e
    end
    return result
  end

  def names
    collect { |e| e.name }
  end
end
