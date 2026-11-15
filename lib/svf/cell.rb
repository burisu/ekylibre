module SVF
  class Cell
    attr_reader :name, :type, :length, :format, :options, :default, :start

    def initialize(name, definition, start = nil)
      @name = name.to_sym
      if definition.is_a? String
        definition = { type: definition }
      elsif definition.is_a? Hash
        definition.symbolize_keys!
      else
        return nil
      end
      if definition[:type] =~ /\-/
        type, format = definition[:type].split('-')[0..1]
        definition = { type: type.to_sym }
        if format =~ /^\d+$/
          definition[:length] = format.to_i
        elsif type.to_sym == :float && format.match(/^\d+\.\d+$/)
          definition[:format] = format
          definition[:length] = format.split('.').inject(1) { |s, e| s += e.to_i }
        elsif type.to_sym == :decimal && format.match(/^\d+\.\d+$/)
          definition[:format] = format
          definition[:length] = format.split('.').first.to_i
        end
      else
        definition[:type] = definition[:type].to_sym
      end
      @type = definition.delete(:type)
      if @type == :boolean
        definition[:length] = 1
      elsif @type == :date
        definition[:length] = 8
      end
      @length = definition.delete(:length)
      raise definition.inspect if @length.nil?

      @format = definition.delete(:format)
      @options = definition.delete(:options) || {}
      @default = definition.delete(:default)
      @start = start
    end

    def required?
      false
    end

    def inspect
      "#{name}(#{type}/#{length})"
    end

    # Value of the cell in the given line
    def parse(line)
      raw = line[start..(start + length - 1)]
      case type
      when :boolean then raw == '1'
      when :date then raw.blank? ? nil : Date.civil(line[(start + 4)..(start + 7)].to_i, line[(start + 2)..(start + 3)].to_i, line[start..(start + 1)].to_i)
      when :integer then raw.to_s.strip.to_i
      when :float then raw.blank? ? 0.0 : raw.to_s.tr(',', '.').to_d
      when :decimal
        decimal_size = format.split('.').last.to_i
        (line[start...(start + length - decimal_size)] + '.' + line[(start + length - decimal_size)...(start + length)]).to_d
      when :string then raw.to_s.strip.encode('UTF-8')
      else raw
      end
    end

    def stop
      @start + length - 1
    end

    # Value formatted for the cell
    def format_value(value)
      case type
      when :boolean then value ? '1' : '0'
      when :date then value.nil? ? ' ' * 8 : value.strftime('%d%m%Y')
      when :integer then value.to_i.to_s.rjust(length)[0..(length - 1)]
      when :float
        decimals = @format.split('.')[1].to_i
        (value.to_i.to_s + ',' + ((value - value.to_i) * 10**decimals).to_i.abs.to_s.rjust(decimals, '0')).rjust(length)[0..(length - 1)]
      when :string then value.to_s.rjust(length)[0..(length - 1)]
      end
    end
  end
end
