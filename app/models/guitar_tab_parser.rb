class GuitarTabParser < Parslet::Parser
  def stri(str)
    key_chars = str.split(//)
    key_chars.
      collect! { |char| match["#{char.upcase}#{char.downcase}"] }.
      reduce(:>>)
  end

  # Utilities
  rule(:eol) { str("\n") }
  rule(:space) { match["\t "] }
  rule(:space?) { space.repeat }
  rule(:empty_line) { space? >> eol }
  rule(:line_char) { (eol.absent? >> any) }

  # Music
  rule(:chord_root) { match['A-G'] }
  rule(:chord) do
    chord_root.as(:chord_root) >>
    ( str("#") | str("b") ).maybe.as(:root_modifier) >>
    str("m").maybe.as(:minor) >>
    ( str("add").maybe >>
        (str("maj").maybe | str("min").maybe).as(:extension_modifier) >>
        ( str("7") | str("9") | str("11") | str("13") ).as(:extension)
    ).maybe >>
    ( str("sus").maybe.as(:suspended) >> ( str("4") | str("2") ).maybe.as(:suspension) ).maybe >>
    ( str("sus").maybe.as(:diminished) >> ( str("4") | str("2") ).maybe.as(:diminishee) ).maybe
  end

  # Sections
  rule(:fluff) { ( stri("tabbed by") >> line_char.repeat >> eol ) }

  rule(:lyric_line) { str("[").absent? >> line_char.repeat(1) >> eol }
  rule(:chord_line) { (chord >> space.repeat(1)).repeat(1) >> eol }
  rule(:chording) do
    # First line can't be empty but other ones can
    ( chord_line.as(:chords) | lyric_line.as(:lyrics) ) >>
    ( empty_line | chord_line.as(:chords) | lyric_line.as(:lyrics) ).repeat(0)
  end

  rule(:tab_staff_line) { str('-').repeat(1) >> eol }
  rule(:tab_staff) { tab_staff_line.repeat(1, 8) }

  rule(:unrecognized_lines) { (str("[").absent? >> line_char.repeat(1) >> eol).repeat(1) }

   # Root
  rule(:section_header) do
    space? >>
    str('[') >> (str(']').absent? >> any).repeat(1).as(:header_name) >> str(']') >>
    line_char.repeat(0).as(:header_fluff) >>
    eol
  end

  rule(:section_contents) do
    fluff.as(:fluff_lines) |
    chording.as(:chord_lines) |
    tab_staff.as(:tab_lines) |
    unrecognized_lines.as(:unrecognized_lines)
  end

  rule(:section) do
    ( empty_line.repeat(0) >> section_header.as(:header) >> empty_line.repeat(0) >> section_contents.maybe.as(:contents) >> empty_line.repeat(0) ) |
    ( empty_line.repeat(0) >> section_contents.maybe.as(:contents) >> empty_line.repeat(1) )
  end

  rule(:tab) { section.as(:section).repeat(1) }
  root(:tab)

  def parse(text)
    super("#{text}\n")
  end
end