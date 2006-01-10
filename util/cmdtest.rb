#! /usr/bin/env ruby

require 'prefix_words_matches'
require 'readline'
require 'pp'

Commands = ({ ['foo'] => nil,
              ['foo', 'bar'] => nil,
              ['foo', 'barsson'] => nil,
              ['food'] => nil,
              ['ost'] => nil })

loop do
  input = Readline.readline('> ')
  words = input.strip.split
  pp Commands.prefix_words_matches(words)
end
