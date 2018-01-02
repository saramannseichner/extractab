# frozen_string_literal: true
module Music
  class UnboundNote
    NOTES_TO_SEMITONES = {
      'C' => 0,
      'C#' => 1,
      'Db' => 1,
      'D' => 2,
      'D#' => 3,
      'Eb' => 3,
      'E' => 4,
      'F' => 5,
      'F#' => 6,
      'Gb' => 6,
      'G' => 7,
      'G#' => 8,
      'Ab' => 9,
      'A' => 10,
      'A#' => 11,
      'Bb' => 11,
      'B' => 12
    }
    SEMITONES_TO_FLAT_NOTES = NOTES_TO_SEMITONES.reject { |k, _v| k.include? '#' }.invert
    SEMITONES_TO_SHARP_NOTES = NOTES_TO_SEMITONES.reject { |k, _v| k.include? 'b' }.invert

    class << self
      def symbolic(string)
        new(string.to_s)
      end
    end

    attr_reader :symbol, :semitones_above_c

    def initialize(normalized_symbol)
      @symbol = normalized_symbol
      @semitones_above_c = NOTES_TO_SEMITONES[@symbol]
    end

    include Comparable
    def <=>(other)
      if other.class == self.class
        self.semitones_above_c <=> other.semitones_above_c
      else
        -1
      end
    end

    def ==(other)
      if other.class == self.class
        self.semitones_above_c == other.semitones_above_c
      end
    end
    alias :eql? :==

    def apply_interval(interval)
      semitones = (NOTES_TO_SEMITONES[@letter] + interval.semitones) % 12
      symbol = if @letter.include? 'b'
        SEMITONES_TO_FLAT_NOTES[semitones]
      else
        SEMITONES_TO_SHARP_NOTES[semitones]
      end

      self.class.new(symbol)
    end

    def note?
      true
    end
  end
end