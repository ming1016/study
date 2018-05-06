def shellsplit(line)
  words = []
  field = ''
  line.scan(/\G\s*(?>([^\s\\\'\"]+)|'([^\']*)'|"((?:[^\"\\]|\\.)*)"|(\\.?)|(\S))(\s|\z)?/m) do
    |word, sq, dq, esc, garbage, sep|
    raise ArgumentError, "Unmatched double quote: #{line.inspect}" if garbage
    field << (word || sq || (dq || esc).gsub(/\\(.)/, '\\1'))
    if sep
      words << field
      field = ''
    end
  end
  words
end
