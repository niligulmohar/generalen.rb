require 'generalen/textinterface'

module Person
  class Person
    def initialize
    end
    def name
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
    attr_reader :games
    def initialize
      @current_game = nil
      @games = OrderedHash.new
      @messages = []
      super
    end
    def post_map_message(message)
      @map_message = message
    end
    def post(message)
      @messages << message
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
        string = messages.join("\n\n")
        while string.length > MAXLENGTH
          $kombot.send_message(@personno, string[0...MAXLENGTH])
          string = string[MAXLENGTH..-1]
        end
        if not string.empty?
          $kombot.send_message(@personno, string)
        end
      rescue Kom::MessageNotSent
        puts "Trasigt"
      else
        @map_message = nil
        @messages.clear
      end
    end
    def name
      $kombot.conf_name(@personno)
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
    def flush
      puts @messages.join("\n\n")
      @messages.clear
    end
  end
end
