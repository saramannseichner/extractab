# frozen_string_literal: true

module Music
  # Represents a chord as a root plus a variable number of intervals (positive or negative). The chord isn't
  # bound to a particular octave or guitar tuning or anything, it's just floating in space relative to the root.
  # This is useful for representing chords in the abstract before dictating exactly how and where to play them on
  # the neck of the guitar or the piano to make that "binding" step of deciding where along the neck or the piano
  # the chord should actually sit.
  # The intervals themselves are unbound and always sorted lowest to highest. Inversions can however be represented
  # using some negative intervals and some positive intervals. the notes that would be above the root in the standard
  # voicing of the chord can be given using the inverse (negative) interval such that they are now below the root.
  class UnboundChord
    class UnknownChordTypeException < RuntimeError; end
    CHORD_INTERVALS = {
      minor: [Intervals::MINOR_THIRD, Intervals::PERFECT_FIFTH],
      major: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH],
      fifth: [Intervals::PERFECT_FIFTH],
      diminished: [Intervals::MINOR_THIRD, Intervals::DIMINISHED_FIFTH],
      augmented: [Intervals::MAJOR_THIRD, Intervals::AUGMENTED_FIFTH],
      major_sixth: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MAJOR_SIXTH],
      minor_sixth: [Intervals::MINOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MAJOR_SIXTH],
      major_seventh: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MAJOR_SEVENTH],
      minor_seventh: [Intervals::MINOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MINOR_SEVENTH],
      diminished_seventh: [Intervals::MINOR_THIRD, Intervals::DIMINISHED_FIFTH, Intervals::DIMINISHED_SEVENTH],
      augmented_seventh: [Intervals::MAJOR_THIRD, Intervals::AUGMENTED_FIFTH, Intervals::MINOR_SEVENTH],
      dominant_seventh: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MINOR_SEVENTH],
      minor_major_seventh: [Intervals::MINOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MAJOR_SEVENTH],
      half_diminished_seventh: [Intervals::MINOR_THIRD, Intervals::DIMINISHED_FIFTH, Intervals::MINOR_SEVENTH],
      major_ninth: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MAJOR_SEVENTH, Intervals::OCTAVE + Intervals::MAJOR_SECOND],
      minor_ninth: [Intervals::MINOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MINOR_SEVENTH, Intervals::OCTAVE + Intervals::MAJOR_SECOND],
      ninth: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MINOR_SEVENTH, Intervals::OCTAVE + Intervals::MAJOR_SECOND],
      major_eleventh: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MAJOR_SEVENTH, Intervals::OCTAVE + Intervals::PERFECT_FOURTH],
      minor_eleventh: [Intervals::MINOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MINOR_SEVENTH, Intervals::OCTAVE + Intervals::PERFECT_FOURTH],
      eleventh: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MINOR_SEVENTH, Intervals::OCTAVE + Intervals::PERFECT_FOURTH],
      major_thirteenth: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MAJOR_SEVENTH, Intervals::OCTAVE + Intervals::MAJOR_SIXTH],
      minor_thirteenth: [Intervals::MINOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MINOR_SEVENTH, Intervals::OCTAVE + Intervals::MAJOR_SIXTH],
      thirteenth: [Intervals::MAJOR_THIRD, Intervals::PERFECT_FIFTH, Intervals::MINOR_SEVENTH, Intervals::OCTAVE + Intervals::MAJOR_SIXTH]
    }.each_value(&:freeze).freeze

    class << self
      def for(root:, type:, substitute_root: nil)
        raise UnknownChordTypeException, "No chord type of #{type} known" unless CHORD_INTERVALS.include?(type)
        root = Music::UnboundNote.symbolic(root)
        intervals = CHORD_INTERVALS[type]

        if substitute_root
          substitute_root = Music::UnboundNote.symbolic(substitute_root)
          intervals = intervals.dup

          positive_interval = Music::Interval.from(root, substitute_root).positive_inversion
          negative_interval = positive_interval.invert
          intervals.delete(positive_interval)
          intervals << negative_interval
        end

        new(root, intervals)
      end
    end

    attr_reader :root, :intervals

    def initialize(root, intervals)
      raise "Root note of a chord must be a Note class" unless root.respond_to?(:note?) && root.note?
      raise "Can't have duplicate notes in a chord, got: #{intervals.inspect} " unless intervals.uniq.size == intervals.size
      @root = root
      @intervals = intervals.sort
    end

    def notes
      @intervals.map { |interval| root.apply_interval(interval) }.unshift(@root)
    end

    def notes_string
      notes.map(&:symbol).join(' ')
    end

    def ==(other)
      if other.class == self.class
        root == other.root &&
          intervals.zip(other.intervals).all? { |self_interval, other_interval| self_interval == other_interval }
      end
    end
    alias_method :eql?, :==

    # tests if a different bound or unbound chord contains the same notes but in any order, octave, or with repetition
    def equivalent?(other_chord)
      other_notes = other_chord.notes.map(&:unbind)
      notes.uniq.sort == other_notes.uniq.sort
    end
  end
end
