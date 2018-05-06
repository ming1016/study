require 'ripper'
require 'pp'
require 'json'
require 'optparse'


# --------------------- utils ---------------------
def banner(s)
  puts "\033[93m#{s}:\033[0m"
end


class AstSimplifier

  def initialize(filename)
    @filename = filename

    f = File.open(filename, 'rb')
    @src = f.read
    f.close

    detected_enc = detect_encoding(@src)
    if detected_enc
      begin
        @src.force_encoding(detected_enc)
      rescue
        @src.force_encoding('utf-8')
      end
    else
      # default to UTF-8
      @src.force_encoding('utf-8')
    end

    @src.encode('utf-8',
                {:undef => :replace,
                 :invalid => :replace,
                 :universal_newline => true}
    )

    @line_starts = [0]
    find_line_starts
    find_docs
  end


  def detect_encoding(s)
    # take first two lines
    header = s.match('^.*\n?.*\n?')
    if header and header[0]
      matched = header[0].match('^\s*#.*coding\s*[:=]\s*([\w\d\-]+)')
      if matched and matched[1]
        matched[1]
      end
    end
  end


  # initialize the @line_starts array
  # used to convert (line,col) location to (start,end)
  def find_line_starts
    lines = @src.split(/\n/)
    total = 0
    lines.each { |line|
      total += line.length + 1 # line and \n
      @line_starts.push(total)
    }
  end


  def find_docs
    @docs = {}
    lines = @src.split(/\n/)
    first_line = nil
    current_line = 0
    accum = []

    lines.each { |line|
      matched = line.match('^\s*#\s*(.*)')
      if matched
        accum.push(matched[1])
        if !first_line
          first_line = current_line
        end
      elsif !accum.empty?
        doc = {
            :type => :string,
            :id => accum.join('\n'),
        }
        @docs[current_line+1] = doc
        @docs[first_line-1] = doc
        accum.clear
        first_line = nil
      end

      current_line += 1
    }
  end


  def node_start(loc)
    line = loc[0]
    col = loc[1]
    @line_starts[line-1] + col
  end


  def ident_end(start_idx)
    if @src[start_idx] == '[' and @src[start_idx + 1] == ']'
      return start_idx + 2
    end
    idx = start_idx
    while idx < @src.length and @src[idx].match /[[:alpha:]0-9_@$\?!]/
      idx += 1
    end
    idx
  end


  def simplify
    tree = Ripper::SexpBuilder.new(@src).parse

    if $options[:debug]
      banner 'sexp'
      pp tree
    end

    simplified = convert(tree)
    simplified = find_locations(simplified)

    if $options[:debug]
      banner 'simplified'
      pp simplified
    end

    simplified
  end


  def find_locations(obj)
    def find1(obj)
      if obj.is_a?(Hash)
        #if obj[:type] == :binary and not obj[:left]
        #  puts "problem obj: #{obj.inspect}"
        #end
        ret = {}
        whole_start = nil
        whole_end = nil
        start_line = nil
        end_line = nil

        obj.each do |k, v|
          if k == :location
            start_idx = node_start(v)
            end_idx = ident_end(start_idx)
            ret[:start] = start_idx
            ret[:end] = end_idx
            ret[:start_line] = v[0]
            ret[:end_line] = v[1]
            whole_start = start_idx
            whole_end = end_idx
            start_line = v[0]
            end_line = v[1]
          else
            new_node, start_idx, end_idx, line_start, line_end = find1(v)
            ret[k] = new_node

            if start_idx && (!whole_start || whole_start > start_idx)
              whole_start = start_idx
              start_line = line_start
            end

            if end_idx && (!whole_end || whole_end < end_idx)
              whole_end = end_idx
              end_line = line_end
            end
          end
        end

        if whole_start
          # push whole_end to 'end' keyword
          if [:module, :class, :def, :lambda, :if, :begin, :while, :for]
              .include?(obj[:type]) and not obj[:mod]
            locator = whole_end
            while locator <= @src.length and
                not 'end'.eql? @src[locator .. locator + 'end'.length-1]
              locator += 1
            end
            if 'end'.eql? @src[locator .. locator + 'end'.length-1]
              whole_end = locator + 'end'.length
            end
          end

          ret[:start] = whole_start
          ret[:end] = whole_end
          ret[:start_line] = start_line
          ret[:end_line] = end_line

          # insert docstrings for node if any
          if [:module, :class, :def].include?(ret[:type])
            doc = @docs[start_line]
            if doc
              ret[:doc] = doc
            end
          end
        end
        return ret, whole_start, whole_end, start_line, end_line

      elsif obj.is_a?(Array)
        ret = []
        whole_start = nil
        whole_end = nil

        for v in obj
          new_node, start_idx, end_idx, line_start, line_end = find1(v)
          ret.push(new_node)
          if  start_idx && (!whole_start || whole_start > start_idx)
            whole_start = start_idx
            start_line = line_start
          end

          if end_idx && (!whole_end || whole_end < end_idx)
            whole_end = end_idx
            end_line = line_end
          end
        end

        return ret, whole_start, whole_end, start_line, end_line
      else
        return obj, nil, nil, nil, nil
      end
    end

    node, _, _, _, _ = find1(obj)
    node
  end


  # ------------------- conversion --------------------
  # convert and simplify ruby's "sexp" into a hash
  # exp -> hash
  def convert(exp)
    if exp == nil
      {}
    elsif exp == false
      {
          :type => :name,
          :id => 'false',
      }
    elsif exp == true
      {
          :type => :name,
          :id => 'true',
      }
    else
      case exp[0]
        when :program
          {
              :type => :program,
              :body => convert(exp[1]),
              :filename => @filename
          }
        when :module
          {
              :type => :module,
              :name => convert(exp[1]),
              :body => convert(exp[2]),
              :filename => @filename
          }
        when :@ident, :@op
          {
              :type => :name,
              :id => exp[1],
              :location => exp[2],
          }
        when :@gvar
          {
              :type => :gvar,
              :id => exp[1],
              :location => exp[2]
          }
        when :dyna_symbol
          # ignore dynamic symbols for now
          {
              :type => :name,
              :id => '#dyna_symbol'
          }
        when :symbol
          sym = convert(exp[1])
          sym[:type] = :symbol
          sym
        when :@cvar
          {
              :type => :cvar,
              :id => exp[1][2..-1],
              :location => exp[2]
          }
        when :@ivar
          {
              :type => :ivar,
              :id => exp[1][1..-1],
              :location => exp[2]
          }
        when :@const, :@kw, :@backtick
          #:@const and :@kw are just names
          {
              :type => :name,
              :id => exp[1],
              :location => exp[2]
          }
        when :@label
          {
              :type => :name,
              :id => exp[1][0..-2],
              :location => exp[2]
          }
        when :def
          {
              :type => :def,
              :name => convert(exp[1]),
              :params => convert(exp[2]),
              :body => convert(exp[3])
          }
        when :defs
          name = {
              :type => :attribute,
              :value => convert(exp[1]),
              :attr => convert(exp[3])
          }
          {
              :type => :def,
              :name => name,
              :params => convert(exp[4]),
              :body => convert(exp[5])
          }
        when :do_block
          {
              :type => :lambda,
              :params => convert(exp[1]),
              :body => convert(exp[2])
          }
        when :lambda
          {
              :type => :lambda,
              :params => convert(exp[1]),
              :body => convert(exp[2])
          }
        when :brace_block
          {
              :type => :lambda,
              :params => convert(exp[1]),
              :body => convert(exp[2])
          }
        when :params
          ret = {:type => :params}
          if exp[1]
            ret[:positional] = convert_array(exp[1])
          end
          if exp[2]
            # keyword arguments (converted into positionals and defaults)
            unless ret[:positional]
              ret[:positional] = []
            end
            exp[2].each { |x| ret[:positional].push(convert(x[0])) }
            ret[:defaults] = exp[2].map { |x| convert(x[1]) }
          end
          if exp[3] and exp[3] != 0
            ret[:rest] = convert(exp[3])
          end
          if exp[4]
            ret[:after_rest] = convert_array(exp[4])
          end
          if exp[6]
            ret[:rest_kw] = convert(exp[6])
          end
          if exp[7]
            ret[:blockarg] = convert(exp[7])
          end
          ret
        when :block_var
          params = convert(exp[1])
          if exp[2]
            params[:block_var] = convert_array(exp[2])
          end
          params
        when :class
          ret = {
              :type => :class,
              :static => false,
              :name => convert(exp[1]),
              :body => convert(exp[3]),
          }
          if exp[2]
            ret[:super] = convert(exp[2])
          end
          ret
        when :sclass
          {
              :type => :class,
              :static => true,
              :name => convert(exp[1]),
              :body => convert(exp[2]),
          }
        when :method_add_block
          call = convert(exp[1])
          if call[:args]
            call[:args][:blockarg] = convert(exp[2])
          else
            call[:args] = {
              :blockarg => convert(exp[2])
            }
          end
          call
        when :method_add_arg
          call = convert(exp[1])
          call[:args] = convert(exp[2])
          call
        when :vcall
          {
              :type => :call,
              :func => convert(exp[1])
          }
        when :command
          {
              :type => :call,
              :func => convert(exp[1]),
              :args => convert(exp[2])
          }
        when :command_call
          if exp[2] == :'.' or exp[2] == :'::'
            func = {
                :type => :attribute,
                :value => convert(exp[1]),
                :attr => convert(exp[3])
            }
          else
            func = convert(exp[1])
          end
          {
              :type => :call,
              :func => func,
              :args => convert(exp[4])
          }
        when :super, :zsuper
          {
              :type => :call,
              :func => {:type => :name, :id => :super},
              :args => convert(exp[1])
          }
        when :call, :fcall
          if exp[3] != :call and (exp[2] == :'.' or exp[2] == :'::')
            func = {
                :type => :attribute,
                :value => convert(exp[1]),
                :attr => convert(exp[3])
            }
          else
            func = convert(exp[1])
          end
          {
              :type => :call,
              :func => func
          }
        when :args_new, :mlhs_new, :mrhs_new, :words_new, :word_new, :qwords_new, :qsymbols_new, :symbols_new
          {
              :type => :args,
              :positional => []
          }
        when :args_add, :mlhs_add, :mrhs_add, :word_add, :words_add, :qwords_add, :qsymbols_add, :symbols_add
          args = convert(exp[1])
          args[:positional].push(convert(exp[2]))
          args
        when :args_add_star, :mrhs_add_star, :mlhs_add_star
          args = convert(exp[1])
          if exp[2]
            args[:star] = convert(exp[2])
          end
          args
        when :args_add_block
          args = convert(exp[1])
          if exp[2]
            args[:blockarg] = convert(exp[2])
          end
          args
        when :assign, :massign
          {
              :type => :assign,
              :target => convert(exp[1]),
              :value => convert(exp[2])
          }
        when :opassign
          # convert x+=1 into x=x+1
          operation = convert([:binary, exp[1], exp[2][1][0..-2], exp[3]])
          {
              :type => :assign,
              :target => convert(exp[1]),
              :value => operation
          }
        when :dot2, :dot3
          {
              :type => exp[0],
              :from => convert(exp[1]),
              :to => convert(exp[2])
          }
        when :alias, :var_alias
          {
              :type => :assign,
              :target => convert(exp[1]),
              :value => convert(exp[2])
          }
        when :undef
          {
              :type => :undef,
              :names => convert_array(exp[1]),
          }
        when :if, :if_mod, :elsif, :ifop
          ret = {
              :type => :if,
              :test => convert(exp[1]),
              :body => convert(exp[2]),
          }
          if exp[3]
            ret[:else] = convert(exp[3])
          end
          if exp[0] == :if_mod
            ret[:mod] = true
          end
          ret
        when :case
          if exp[1]
            value = convert(exp[1])
          else
            value = nil
          end
          convert_when(exp[2], value)
        when :while, :while_mod
          if exp[0] == :while_mod
            mod = true
          else
            mod = false
          end
          {
              :type => :while,
              :test => convert(exp[1]),
              :body => convert(exp[2]),
              :mod => mod
          }
        when :until, :until_mod
          if exp[0] == :until_mod
            mod = true
          else
            mod = false
          end
          {
              :type => :while,
              :test => negate(convert(exp[1])),
              :body => convert(exp[2]),
              :mod => mod
          }
        when :unless, :unless_mod
          if exp[0] == :unless_mod
            mod = true
          else
            mod = false
          end
          ret = {
              :type => :if,
              :test => negate(convert(exp[1])),
              :body => convert(exp[2]),
              :mod => mod
          }
          if exp[3]
            ret[:else] = convert(exp[3])
          end
          ret
        when :for
          {
              :type => :for,
              :target => convert(exp[1]),
              :iter => convert(exp[2]),
              :body => convert(exp[3])
          }
        when :begin
          bodystmt = exp[1]
          {
              :type => :begin,
              :body => convert(bodystmt[1]),
              :rescue => convert(bodystmt[2]),
              :else => convert(bodystmt[3]),
              :ensure => convert(bodystmt[4])
          }
        when :rescue
          ret = {:type => :rescue}
          if exp[1]
            if exp[1][0].is_a? Array
              ret[:exceptions] = convert_array(exp[1])
            else
              ret[:expections] = convert(exp[1])[:positional]
            end
          end
          if exp[2]
            ret[:binder] = convert(exp[2])
          end
          if exp[3]
            ret[:handler] = convert(exp[3])
          end
          if exp[4]
            ret[:else] = convert(exp[4])
          end
          ret
        when :rescue_mod
          {
              :type => :begin,
              :body => convert(exp[1]),
              :rescue => convert(exp[2]),
              :mod => true
          }
        when :stmts_new
          {
              :type => :block,
              :stmts => []
          }
        when :stmts_add
          block = convert(exp[1])
          stmt = convert(exp[2])
          block[:stmts].push(stmt)
          block
        when :bodystmt
          block = convert(exp[1])
          if exp[2]
            res = convert(exp[2])
            block[:stmts].push(res)
          end
          block
        when :binary
          {
              :type => :binary,
              :left => convert(exp[1]),
              :op => op(exp[2]),
              :right => convert(exp[3])
          }
        when :array
          args = convert(exp[1])
          {
              :type => :array,
              :elts => args[:positional]
          }
        when :aref, :aref_field
          args = convert(exp[2])
          {
              :type => :subscript,
              :value => convert(exp[1]),
              :slice => args[:positional]
          }
        when :unary
          {
              :type => :unary,
              :op => op(exp[1]),
              :operand => convert(exp[2])
          }
        when :@int
          {
              :type => :int,
              :value => exp[1],
              :location => exp[2]
          }
        when :@float
          {
              :type => :float,
              :value => exp[1],
              :location => exp[2]
          }
        when :regexp_literal
          regexp = convert(exp[1])
          regexp[:regexp_end] = convert(exp[2])
          regexp
        when :regexp_new
          {
              :type => :regexp,
          }
        when :regexp_add
          {
              :type => :regexp,
              :pattern => convert(exp[2]),
          }
        when :@regexp_end
          make_string(exp[1], exp[2])
        when :@backref
          make_string(exp[1], exp[2])
        when :@tstring_content, :@CHAR
          make_string(exp[1], exp[2])
        when :string_content, :xstring_new
          make_string('')
        when :string_add, :xstring_add, :qwords_add
          if not exp[1] or exp[1] == [:string_content] or exp[1] == [:xstring_new]
            convert(exp[2])
          else
            {
                :type => :binary,
                :op => op(:+),
                :left => convert(exp[1]),
                :right => convert(exp[2])
            }
          end
        when :string_concat, :xstring_concat
          convert([:binary, exp[1], :+, exp[2]])
        when :hash
          if exp[1]
            convert(exp[1])
          else
            {
                :type => :hash,
            }
          end
        when :assoclist_from_args, :bare_assoc_hash
          {
              :type => :hash,
              :entries => convert_array(exp[1])
          }
        when :assoc_new
          {
              :type => :assoc,
              :key => convert(exp[1]),
              :value => convert(exp[2])
          }
        when :const_path_ref, :const_path_field
          {
              :type => :attribute,
              :value => convert(exp[1]),
              :attr => convert(exp[2])
          }
        when :field
          {
              :type => :attribute,
              :value => convert(exp[1]),
              :attr => convert(exp[3])
          }
        when :void_stmt
          {
              :type => :void
          }
        when :yield0
          {
              :type => :yield
          }
        when :return0
          {
              :type => :return
          }
        when :break
          {
              :type => :break
          }
        when :retry
          {
              :type => :retry
          }
        when :redo
          {
              :type => :redo
          }
        when :defined
          {
              :type => :unary,
              :op => op(:defined),
              :operand => convert(exp[1])
          }
        when :return, :yield
          {
              :type => exp[0],
              :value => args_to_array(convert(exp[1]))
          }
        when :string_embexpr
          {
              :type => :string_embexpr,
              :value => convert(exp[1])
          }
        when :var_ref,
            :var_field,
            :const_ref,
            :top_const_ref,
            :top_const_field,
            :paren,
            :else,
            :ensure,
            :arg_paren,
            :mlhs_paren,
            :rest_param,
            :blockarg,
            :symbol_literal,
            :regexp_literal,
            :param_error,
            :string_literal,
            :xstring_literal,
            :string_dvar,
            :mrhs_new_from_args,
            :assoc_splat,
            :next,
            :END,
            :BEGIN
          # superflous wrappers that contains one object, just remove it
          convert(exp[1])
        else
          banner('unknown')
          puts "#{exp}"
          exp
      end
    end
  end


  def convert_array(arr)
    arr.map { |x| convert(x) }
  end


  def convert_when(exp, value)
    if exp[0] == :when
      if value
        test = {
            :type => :binary,
            :op => op(:in),
            :left => value,
            :right => args_to_array(convert(exp[1]))
        }
      else
        test = args_to_array(convert(exp[1]))
      end
      ret = {
          :type => :if,
          :test => test,
          :body => convert(exp[2]),
      }
      if exp[3]
        ret[:else] = convert_when(exp[3], value)
      end
      ret
    elsif exp[0] == :else
      convert(exp[1])
    end
  end


  def args_to_array(args)
    if args[:type] == :args
      {
          :type => :array,
          :elts => args[:positional]
      }
    else
      args
    end
  end


  def make_string(content, location=nil)
    ret = {
        :type => :string,
        :id => content.force_encoding('utf-8'),
    }
    if location
      ret[:location] = location
    end
    ret
  end


  def op(name)
    {
        :type => :op,
        :name => name
    }
  end


  def negate(exp)
    {
        :type => :unary,
        :op => op(:not),
        :operand => exp
    }
  end

end


def parse_dump(input, output, endmark)
  begin
    simplifier = AstSimplifier.new(input)
    hash = simplifier.simplify

    json_string = JSON.pretty_generate(hash)
    out = File.open(output, 'wb')
    out.write(json_string)
    out.close
  ensure
    end_file = File.open(endmark, 'wb')
    end_file.close
  end
end


$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: dump_ruby.rb [options]"

  opts.on("-d", "--debug", "debug run") do |v|
    $options[:debug] = v
  end

end.parse!


if ARGV.length > 0
  parse_dump(ARGV[0], ARGV[1], ARGV[2])
end

