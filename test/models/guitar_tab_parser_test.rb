# frozen_string_literal: true
require 'test_helper'

class GuitarTabParserTest < ActiveSupport::TestCase
  setup do
    @parser = GuitarTabParser.new
  end

  test "it parses just an intro section" do
    parse <<~TAB
      [Intro]
    TAB

    parse <<~TAB
      [Intro]

    TAB

    parse <<~TAB
      [Intro]


    TAB

    parse <<~TAB
      [Intro]

    TAB

    parse <<~TAB
      [Intro]

    TAB

    parse "\n[Intro]"
    parse "\n\n[Intro]"
  end

  test "it parses multiple sections with headers" do
    parse <<~TAB
      [Intro]
      [Verse]
      [Chorus]
    TAB

    parse <<~TAB
      [Intro]
      [Verse]
      [Chorus]

    TAB

    parse <<~TAB
      [Intro]
      [Verse]
      [Chorus]


    TAB
  end

  test "it parses sections with plain old chords" do
    expected = [{:section=>{:header=>{:header_name=>"Intro", :header_fluff=>[]}, :contents=>{:chord_lines=>{:chords=>[{:chord=>{:chord_root=>"E", :major_minor=>"m"}}, {:chord=>{:chord_root=>"Bb", :major_minor=>nil}}, {:chord=>{:chord_root=>"C", :major_minor=>"m"}}]}}}}, {:section=>{:header=>{:header_name=>"Verse", :header_fluff=>[]}, :contents=>{:chord_lines=>{:chords=>[{:chord=>{:chord_root=>"E", :major_minor=>"m"}}, {:chord=>{:chord_root=>"A", :major_minor=>nil}}, {:chord=>{:chord_root=>"C", :major_minor=>"m"}}]}}}}]

    result = parse <<~TAB
      [Intro]
      Em Bb Cm
      [Verse]
      Em A Cm
    TAB
    assert_equal expected, result

    result = parse <<~TAB
       [Intro]
      Em Bb Cm
       [Verse]
      Em A Cm
    TAB
    assert_equal expected, result

    result = parse <<~TAB
      [Intro]
      Em Bb Cm
       [Verse]
      Em A Cm


    TAB
    assert_equal expected, result
  end

  test "it parses plain old floof" do
    parse <<~TAB
      Tabbed by: Emrldeyzs
       CAPO 2


    TAB
  end

  test "it recognizes chord definition sections with a header" do
    parsed = parse <<~TAB
    [Chords]
    A6    xx767x
    Amaj7    5x665x
    Bm7    797777
    C#m7    9-11-9-9-9-9
    TAB

    assert parsed[0].key?(:section)
    assert parsed[0][:section][:contents][:chord_definition_lines]

    parsed = parse("    [Chords]\r\n    A6    xx767x\r\n    Amaj7    5x665x\r\n    Bm7    797777\r\n    C#m7    9-11-9-9-9-9")
    assert parsed[0].key?(:section)
    assert parsed[0][:section][:contents][:chord_definition_lines]
  end


  def parse(text)
    @parser.parse(text)
  rescue Parslet::ParseFailed => error
    puts error.parse_failure_cause.ascii_tree
    puts "While parsing <<~TAB"
    puts text
    puts "TAB"
    raise
  end
end
