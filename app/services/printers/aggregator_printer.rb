# frozen_string_literal: true

module Printers
  # Exposes an Aggeratio aggregator to a Liquid template. The aggregator XML
  # is converted to data:
  # - attributes become keys (underscored)
  # - text-only children become string values
  # - other children are grouped in lists by element name
  class AggregatorPrinter < PrinterBase
    attr_reader :aggregator

    def initialize(template:, aggregator:, key:)
      super(template: template)
      @aggregator = aggregator
      @key = key
    end

    attr_reader :key

    def document_name
      "#{aggregator.class.human_name} - #{key}"
    end

    def generate(report)
      document = Nokogiri::XML(aggregator.to_xml.to_s)
      self.class.element_to_hash(document.root).each { |name, value| report.add_field(name, value) }
      report.add_field(:root_name, document.root.name.underscore)
      report.add_field(:printed_at, Time.zone.now.l)
    end

    class << self
      def element_to_hash(element)
        data = element.attribute_nodes.each_with_object({}) { |attr, hash| hash[attr.name.underscore] = attr.value }
        element.element_children.each do |child|
          name = child.name.underscore
          if child.element_children.empty? && child.attribute_nodes.empty?
            data[name] = child.text
          else
            data[name] = [] unless data[name].is_a?(Array)
            data[name] << element_to_hash(child)
          end
        end
        data
      end
    end
  end
end
