# coding: utf-8
#--
# Copyright (c) Nicklas Lindgren 2005-2006
# Det här programmet distribueras under villkoren i GPL v2.
#++

module Game
  module Setting
    class Setting
      def initialize
        @value = default
      end
      def default
        []
      end
      def name
        'Testinställning'
      end
      def description
        'Någon sorts inställning'
      end
      def value
        @value
      end
      def value=(val)
        @value = value
      end
      def to_s
        @value.join(' ')
      end
    end

    class Choice
      attr_reader :name
      attr_reader :value
      def initialize(name, value)
        @name = name
        @value = value
      end
      def to_s
        name
      end
    end

    class ChoiceSetting < Setting
      attr_reader :choices
      def initialize
        @choices = gen_choices
        super
      end
      def default
        @choices[0]
      end
      def name
        'Flervalsinställning'
      end
      def value
        @value.value
      end
      def set(choice)
        if not @choices.include?(choice)
          raise RuntimeError.new('Invalid choice')
        end
        @value = choice
      end
      def to_s
        @value.name
      end
    end

    class GameType < ChoiceSetting
      def gen_choices
        [ Choice.new('Hemligt uppdrag', :mission),
          Choice.new('Världsdominans', :dominance) ]
      end
      def name
        'Speltyp'
      end
      def description
        'Anger partiets vinstvillkor'
      end
    end

    class CardType < ChoiceSetting
      def gen_choices
        [ Choice.new('Enligt kombination', :combination),
          Choice.new('Progressivt', :progressive) ]
      end
      def name
        'Inbytesvärde för kort'
      end
      def description
        'Anger reglerna för hur många arméer kortkombinationer är värda.'
      end
    end

    class Timeout < Setting
      def default
        1500
      end
      def name
        'Dragtid'
      end
      def description
        'Tidsfrist i minuter som en spelare har på sig att genomföra sitt drag'
      end
      def set(int)
        @value = int
      end
      def to_s
        if @value <= 0
          'Obegränsad'
        else
          hours = @value / 60
          minutes = @value % 60
          parts = []
          parts << hours.swedish_quantity('timme', 'timmar') if hours > 0
          parts << minutes.swedish_quantity('minut', 'minuter') if minutes > 0
          '%d (%s)' % [@value, parts.swedish]
        end
      end
    end
  end
end
