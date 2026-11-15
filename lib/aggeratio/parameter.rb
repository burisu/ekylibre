module Aggeratio
  class Parameter
    TYPES = %i[record_list record string decimal integer date datetime].freeze
    attr_reader :name, :type, :options, :default

    def initialize(name, type, options = {})
      @name = name.to_s
      @type = type
      @options = options
      raise ArgumentError.new("Type is unknown: #{@type.inspect}") unless TYPES.include?(@type)

      @default = @options[:default]
      raise ArgumentError.new("Default value must be given for #{@name}") unless @default

    end

    # Resolved lazily: models can't be autoloaded while initializing and
    # must not be kept across code reloads
    def foreign_class
      foreign_class_name&.constantize
    end

    def foreign_class_name
      @options[:of].to_s.camelcase if @options[:of]
    end

    # Import parameter form an XML node
    def self.import(element)
      options = element.attributes.each_with_object({}) do |pair, hash|
        hash[pair[0].to_sym] = pair[1].to_s
        hash
      end
      name = options.delete(:name).to_s
      type = options.delete(:type).to_s.tr('-', '_').to_sym
      new(name, type, options)
    end

    def human_name
      ::I18n.t("aggregator_parameters.#{name}", default: [:"labels.#{name}", :"attributes.#{name}", name.to_s.humanize])
    end

    TYPES.each do |type|
      define_method("#{type}?") { self.type == type }
    end
  end
end
