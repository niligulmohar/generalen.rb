# coding: utf-8
#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++
require_relative '../generalen/textinterface'

module Person
  class Person
    def initialize
    end
    def name
    end
    def raw_name
      name
    end
    def administrator?
      false
    end
    def request(params = {})
      $state.request(params.merge(:person => self))
    end
  end

  class TextInterfacePerson < Person
    include TextInterface
    attr_reader :games, :current_game
    def initialize
      @current_game = nil
      @games = OrderedHash.new
      @messages = []
      @delayed_messages = {}
      @quiet = false
      super
    end
    def post_map_message(message)
      @map_message = message
    end
    def post(message)
      @messages << message
    end
    def post_delayed(key, message)
      @delayed_messages ||= {}
      @delayed_messages[key] ||= []
      @delayed_messages[key] << message
    end
    def post_maybe_delayed(key, message, delayed = true)
      if @quiet and delayed
        post_delayed(key, message)
      else
        post(message)
      end
    end
    def has_delayed?(key)
      @delayed_messages[key] and not @delayed_messages[key].empty?
    end
    def flush_delayed(key)
      @delayed_messages ||= {}
      if has_delayed?(key)
        @messages += @delayed_messages[key]
        @delayed_messages[key] = nil
      end
    end
    def messages
      @map_message ? [@map_message] + @messages : @messages
    end
    def flush
    end
    def get
      @messages.shift
    end
  end

  MAXLENGTH = 8000

  class KomPerson < TextInterfacePerson
    def initialize(personno)
      @personno = personno
      super()
    end
    def flush
      begin
        acc = ''
        messages.each do |msg|
          if acc.length + msg.length + 2 > MAXLENGTH
            if acc.empty?
              $logger.warn('Fetstort meddelande, delas på ett fult sätt')
              string = msg
              while string.length > MAXLENGTH
                send_message(string[0...MAXLENGTH])
                string = string[MAXLENGTH..-1]
              end
              if not string.empty?
                send_message(string)
              end
            else
              send_message(acc)
              acc = msg
            end
          else
            unless acc.empty?
              acc << "\n\n"
            end
            acc << msg
          end
        end
        send_message(acc) unless acc.empty?
      rescue Kom::MessageNotSent
        $logger.error('Kom::MessageNotSent inträffade')
      else
        @map_message = nil
        @messages.clear
      end
    end
    def name
      $kombot.conf_name(@personno)
    end
    private
    def send_message(string)
      $logger.debug("Meddelande till %s:\n%s" % [name, string])
      $kombot.send_message(@personno, string)
    end
  end

  class Administrator < TextInterfacePerson
    def flush
      puts messages.join("\n\n")
      @messages.clear
    end
    def name
      'Generalsstaben'
    end
    def administrator?
      true
    end
  end

  class TestPerson < TextInterfacePerson
    def initialize(name)
      @name = name
      super()
    end
    def name
      @name
    end
    def clear_messages
      @messages.clear
    end
    def flush
      # puts @messages.join("\n\n")
      # @messages.clear
    end
  end
end
