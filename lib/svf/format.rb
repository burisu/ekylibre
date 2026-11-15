module SVF
  # Fixed width file format described in YAML (see lib/svf/norms). It
  # defines SVF::<Name> with a class per line type (SVF::<Name>::Lines::*),
  # a Base class holding the parsed file and SVF::<Name>.parse(file).
  class Format
    attr_reader :name, :lines, :root, :encoding

    def initialize(name, file)
      @name = name
      source = YAML.safe_load_file(file, permitted_classes: [Date, Time, Symbol], aliases: true)
      @lines = {}
      @encoding = source['encoding'] || 'ISO8859-1'
      source['lines'].each do |line_name, line|
        @lines[line_name.to_sym] = Line.new(line_name, line['key'], line['cells'], line['children'], line['to'])
      end
      @root = SVF.occurrencify(source['root'])
    end

    def module_name
      @name.to_s.classify
    end

    # Defines the SVF::<Name> module
    def define
      format = self
      mod = Module.new
      lines_module = Module.new
      mod.const_set(:Lines, lines_module)
      @lines.each_value do |line|
        lines_module.const_set(line.class_name, record_class(line))
      end
      mod.const_set(:Base, base_class)
      mod.define_singleton_method(:format) { format }
      mod.define_singleton_method(:parse) { |file| format.parse(file) }
      SVF.send(:remove_const, module_name) if SVF.const_defined?(module_name, false)
      SVF.const_set(module_name, mod)
    end

    def line_class(line_name)
      SVF.const_get(module_name)::Lines.const_get(@lines[line_name.to_sym].class_name)
    end

    # Parses a line of the file into a line record
    def parse_line(text, number)
      return nil if text.nil?

      line = @lines.values.detect { |definition| text.start_with?(definition.key) }
      return nil unless line

      values = line.cells.map { |cell| cell.parse(text) }
      line_class(line.name).new(*values)
    rescue StandardError => e
      raise if e.is_a?(SVF::InvalidSyntax)

      Rails.logger.warn "[Line ##{number + 1}][#{e.inspect}] Cannot parse #{line&.name}: #{text.inspect}"
      raise SVF::InvalidSyntax, e.message
    end

    def parse(file)
      base = SVF.const_get(module_name)::Base.new
      ::File.open(file, "rb:#{@encoding}") do |io|
        reader = Reader.new(io)
        parse_siblings(reader, @root, base, [], [])
      end
      base
    end

    # Builds the file content of a parsed file
    def build(base)
      string = +''
      build_siblings(string, @root, base)
      string
    end

    private

      # Reads the lines of the given siblings into holder. Returns the first
      # line which belongs to a parent level.
      def parse_siblings(reader, siblings, holder, parents, all_parents)
        line = parse_line(reader.gets, reader.number)
        while line
          if (sibling = siblings.detect { |s| line.is_a?(line_class(s.line)) })
            definition = @lines[sibling.line]
            if sibling.range.max == 1
              holder.public_send("#{sibling.name}=", line)
            else
              holder.public_send(sibling.name) << line
            end
            if definition.to
              text = reader.gets
              while !text.nil? && text =~ /^#{Regexp.escape(definition.to)}\ *$/
                line.text << text
                text = reader.gets
              end
            end
            line = if definition.has_children?
                     parse_siblings(reader, definition.children, line, siblings, siblings + all_parents)
                   else
                     parse_line(reader.gets, reader.number)
                   end
          elsif parents.any? && all_parents.any? { |s| line.is_a?(line_class(s.line)) }
            return line
          else
            raise StandardError, "Unexpected element at line #{reader.number}: #{line.class.name}:#{line.inspect}"
          end
        end
        line
      end

      def build_siblings(string, siblings, holder)
        siblings.each do |sibling|
          value = holder.public_send(sibling.name)
          next unless value

          children = @lines[sibling.line].children
          (sibling.range.max == 1 ? [value] : value).each do |item|
            string << item.to_s
            build_siblings(string, children, item) if children.any?
          end
        end
      end

      def record_class(line)
        Class.new(Record) do
          attr_accessor(*line.cells.map(&:name)) if line.has_cells?
          attr_accessor(*line.children.map { |c| c.name.to_sym }) if line.has_children?
          attr_accessor :text if line.to
          line.cells.select { |c| c.type == :boolean }.each do |cell|
            alias_method :"#{cell.name}?", cell.name
          end
          define_singleton_method(:definition) { line }
        end
      end

      def base_class
        root = @root
        format = self
        Class.new do
          attr_accessor(*root.map { |o| o.name.to_sym })

          define_method(:initialize) do
            root.select(&:numerous?).each { |o| instance_variable_set("@#{o.name}", []) }
          end

          define_method(:to_s) { format.build(self) }
        end
      end
  end

  # A line of a SVF file
  class Record
    def initialize(*values)
      line = self.class.definition
      line.cells.each_with_index { |cell, index| instance_variable_set("@#{cell.name}", values[index]) }
      line.children.reject { |c| c.range.max == 1 }.each { |c| instance_variable_set("@#{c.name}", []) }
      @text = +'' if line.to
    end

    def to_s
      line = self.class.definition
      return nil if line.to

      line.key + line.cells.map { |cell| cell.format_value(instance_variable_get("@#{cell.name}")) }.join + "\r\n"
    end
  end

  # Reads lines and counts them
  class Reader
    attr_reader :number

    def initialize(io)
      @io = io
      @number = -1
    end

    def gets
      @number += 1
      @io.gets
    end
  end
end
