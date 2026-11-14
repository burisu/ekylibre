# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    # Liquid-compatible view of printer data. Keys missing in a table row or
    # a section item are looked up in the parent scope, like odf-report did
    # when filling fields outside of tables.
    class ReportScope
      attr_reader :data, :parent

      def initialize(data, parent = nil)
        @data = data
        @parent = parent
      end

      def key?(key)
        @data.key?(key.to_s) || (@parent ? @parent.key?(key) : false)
      end

      def [](key)
        key = key.to_s
        return liquidize(@data[key]) if @data.key?(key)

        @parent ? @parent[key] : nil
      end

      def has_key?(key) # rubocop:disable Naming/PredicateName
        key?(key)
      end

      # Items of a table/section. A collection not filled by the printer is
      # rendered once with the current scope (static content).
      def collection(name)
        name = name.to_s
        return [self] unless key?(name)

        value = self[name]
        value.is_a?(Array) ? value : [self]
      end

      def to_liquid
        self
      end

      private

        def liquidize(value)
          case value
          when Array then value.map { |item| item.is_a?(Hash) ? ReportScope.new(item, self) : liquidize(item) }
          when Hash then ReportScope.new(value, self)
          when nil then nil
          when String then value
          else value.to_s
          end
        end
    end
  end
end
