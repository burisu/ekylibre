# Aggregators: data sets of the application exported as XML (printed with
# WeasyPrint templates) or HTML (preview), see Aggeratio::Aggregator.
module Aggeratio
  class InvalidDocument < StandardError
  end

  # Aggregators of the application. Plugins add theirs with Aggeratio.register.
  AGGREGATORS = %w[Aggeratio::AnimalHusbandryRegister Aggeratio::VeterinaryBooklet].freeze

  class << self
    def registered
      @registered ||= []
    end

    def register(class_name)
      registered << class_name.to_s unless registered.include?(class_name.to_s)
    end

    def aggregators
      (AGGREGATORS + registered).map(&:constantize)
    end

    def each(&block)
      if block.arity == 2
        aggregators.each { |aggregator| yield aggregator.aggregator_name, aggregator }
      else
        aggregators.each(&block)
      end
    end

    # Returns the names of the aggregators
    def names
      aggregators.map(&:aggregator_name)
    end

    # Give access to named aggregators
    def [](name)
      aggregators.detect { |aggregator| aggregator.aggregator_name == name.to_s }
    end

    def of_category(category)
      aggregators.select { |aggregator| aggregator.category == category.to_s }
    end
  end
end
